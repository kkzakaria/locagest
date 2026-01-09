-- Migration: 006_payments
-- Feature: Payment Management (006-payment-management)
-- Date: 2026-01-08
-- Description: Creates payments table for tracking individual payment transactions

-- ============================================================================
-- PAYMENTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Reference to rent schedule
    rent_schedule_id UUID NOT NULL REFERENCES public.rent_schedules(id) ON DELETE CASCADE,

    -- Payment details
    amount DECIMAL(12,2) NOT NULL,
    payment_date DATE NOT NULL,
    payment_method TEXT NOT NULL CHECK (payment_method IN ('cash', 'check', 'transfer', 'mobile_money')),
    reference TEXT,

    -- Check-specific fields
    check_number TEXT,
    bank_name TEXT,

    -- Receipt
    receipt_number TEXT NOT NULL UNIQUE,

    -- Notes
    notes TEXT,

    -- Audit
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,

    -- Constraints
    CONSTRAINT payments_amount_positive CHECK (amount > 0),
    CONSTRAINT payments_check_fields CHECK (
        (payment_method != 'check') OR (check_number IS NOT NULL)
    )
);

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_payments_schedule ON payments(rent_schedule_id);
CREATE INDEX IF NOT EXISTS idx_payments_date ON payments(payment_date DESC);
CREATE INDEX IF NOT EXISTS idx_payments_receipt ON payments(receipt_number);
CREATE INDEX IF NOT EXISTS idx_payments_created_by ON payments(created_by);
CREATE INDEX IF NOT EXISTS idx_payments_created_at ON payments(created_at DESC);

-- ============================================================================
-- RECEIPT NUMBER GENERATION FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION generate_receipt_number()
RETURNS TEXT AS $$
DECLARE
    current_prefix TEXT;
    next_seq INTEGER;
BEGIN
    current_prefix := 'QUI-' || TO_CHAR(NOW(), 'YYYYMM') || '-';

    SELECT COALESCE(MAX(CAST(SUBSTRING(receipt_number FROM 13) AS INTEGER)), 0) + 1
    INTO next_seq
    FROM payments
    WHERE receipt_number LIKE current_prefix || '%';

    RETURN current_prefix || LPAD(next_seq::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- AUTO-SET RECEIPT NUMBER TRIGGER
-- ============================================================================

CREATE OR REPLACE FUNCTION set_payment_receipt_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.receipt_number IS NULL OR NEW.receipt_number = '' THEN
        NEW.receipt_number := generate_receipt_number();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS payments_set_receipt_number ON payments;
CREATE TRIGGER payments_set_receipt_number
    BEFORE INSERT ON payments
    FOR EACH ROW
    EXECUTE FUNCTION set_payment_receipt_number();

-- ============================================================================
-- AUTO-SET CREATED_BY TRIGGER
-- ============================================================================

CREATE OR REPLACE FUNCTION set_payment_created_by()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.created_by IS NULL THEN
        NEW.created_by := auth.uid();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS payments_set_created_by ON payments;
CREATE TRIGGER payments_set_created_by
    BEFORE INSERT ON payments
    FOR EACH ROW
    EXECUTE FUNCTION set_payment_created_by();

-- ============================================================================
-- UPDATE RENT_SCHEDULE AMOUNTS TRIGGER
-- ============================================================================

CREATE OR REPLACE FUNCTION update_rent_schedule_on_payment()
RETURNS TRIGGER AS $$
DECLARE
    total_paid DECIMAL(12,2);
    schedule_amount_due DECIMAL(12,2);
    schedule_due_date DATE;
    new_status TEXT;
BEGIN
    -- Get the schedule ID based on operation type
    IF TG_OP = 'DELETE' THEN
        -- Calculate new total for the schedule
        SELECT COALESCE(SUM(amount), 0) INTO total_paid
        FROM payments
        WHERE rent_schedule_id = OLD.rent_schedule_id AND id != OLD.id;

        -- Get schedule details
        SELECT amount_due, due_date INTO schedule_amount_due, schedule_due_date
        FROM rent_schedules
        WHERE id = OLD.rent_schedule_id;

        -- Determine new status
        IF total_paid >= schedule_amount_due THEN
            new_status := 'paid';
        ELSIF total_paid > 0 THEN
            new_status := 'partial';
        ELSIF schedule_due_date < CURRENT_DATE THEN
            new_status := 'overdue';
        ELSE
            new_status := 'pending';
        END IF;

        -- Update the schedule
        UPDATE rent_schedules
        SET amount_paid = total_paid,
            status = new_status,
            updated_at = now()
        WHERE id = OLD.rent_schedule_id
          AND status != 'cancelled';

        RETURN OLD;
    ELSE
        -- INSERT or UPDATE
        -- Calculate new total for the schedule
        SELECT COALESCE(SUM(amount), 0) INTO total_paid
        FROM payments
        WHERE rent_schedule_id = NEW.rent_schedule_id;

        -- Get schedule details
        SELECT amount_due, due_date INTO schedule_amount_due, schedule_due_date
        FROM rent_schedules
        WHERE id = NEW.rent_schedule_id;

        -- Determine new status
        IF total_paid >= schedule_amount_due THEN
            new_status := 'paid';
        ELSIF total_paid > 0 THEN
            new_status := 'partial';
        ELSIF schedule_due_date < CURRENT_DATE THEN
            new_status := 'overdue';
        ELSE
            new_status := 'pending';
        END IF;

        -- Update the schedule
        UPDATE rent_schedules
        SET amount_paid = total_paid,
            status = new_status,
            updated_at = now()
        WHERE id = NEW.rent_schedule_id
          AND status != 'cancelled';

        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS payments_update_schedule ON payments;
CREATE TRIGGER payments_update_schedule
    AFTER INSERT OR UPDATE OR DELETE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION update_rent_schedule_on_payment();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "admin_full_access_payments" ON payments;
DROP POLICY IF EXISTS "gestionnaire_own_payments" ON payments;
DROP POLICY IF EXISTS "assistant_read_insert_payments" ON payments;

-- ============================================================================
-- PAYMENTS POLICIES
-- ============================================================================

-- Admin: Full access to all payments
CREATE POLICY "admin_full_access_payments" ON payments
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- Gestionnaire: Full access to payments for their own leases
CREATE POLICY "gestionnaire_own_payments" ON payments
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM rent_schedules rs
            JOIN leases l ON l.id = rs.lease_id
            WHERE rs.id = payments.rent_schedule_id
            AND l.created_by = auth.uid()
        )
        AND EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'gestionnaire'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM rent_schedules rs
            JOIN leases l ON l.id = rs.lease_id
            WHERE rs.id = payments.rent_schedule_id
            AND l.created_by = auth.uid()
        )
        AND EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'gestionnaire'
        )
    );

-- Assistant: Read all payments, can insert new payments
CREATE POLICY "assistant_read_payments" ON payments
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'assistant'
        )
    );

CREATE POLICY "assistant_insert_payments" ON payments
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'assistant'
        )
    );

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE payments IS 'Individual payment transactions recorded against rent schedules';
COMMENT ON COLUMN payments.id IS 'Unique payment identifier';
COMMENT ON COLUMN payments.rent_schedule_id IS 'Reference to the rent schedule this payment applies to';
COMMENT ON COLUMN payments.amount IS 'Payment amount in FCFA';
COMMENT ON COLUMN payments.payment_date IS 'Date payment was received';
COMMENT ON COLUMN payments.payment_method IS 'Method: cash, check, transfer, mobile_money';
COMMENT ON COLUMN payments.reference IS 'Transaction reference for transfers/mobile money';
COMMENT ON COLUMN payments.check_number IS 'Check number (required if method = check)';
COMMENT ON COLUMN payments.bank_name IS 'Bank name for check payments';
COMMENT ON COLUMN payments.receipt_number IS 'Auto-generated receipt number (QUI-AAAAMM-XXXX)';
COMMENT ON COLUMN payments.notes IS 'Optional notes about the payment';
COMMENT ON COLUMN payments.created_by IS 'User who recorded this payment';
COMMENT ON COLUMN payments.created_at IS 'Timestamp when payment was recorded';
