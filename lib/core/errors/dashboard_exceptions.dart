/// Base exception for dashboard operations
class DashboardException implements Exception {
  final String message;
  final dynamic originalError;

  const DashboardException(this.message, [this.originalError]);

  @override
  String toString() => 'DashboardException: $message';
}

/// Exception when dashboard data fails to load
class DashboardLoadException extends DashboardException {
  const DashboardLoadException(super.message, [super.originalError]);

  /// Factory for database query errors
  factory DashboardLoadException.queryFailed([dynamic error]) {
    return DashboardLoadException(
      'Erreur lors du chargement des donnees du tableau de bord',
      error,
    );
  }

  /// Factory for network errors
  factory DashboardLoadException.networkError([dynamic error]) {
    return DashboardLoadException(
      'Erreur de connexion. Verifiez votre connexion internet.',
      error,
    );
  }

  /// Factory for timeout errors
  factory DashboardLoadException.timeout([dynamic error]) {
    return DashboardLoadException(
      'Le chargement a pris trop de temps. Veuillez reessayer.',
      error,
    );
  }
}

/// Exception when user is not authorized to view dashboard
class DashboardUnauthorizedException extends DashboardException {
  const DashboardUnauthorizedException([
    super.message = 'Vous n\'etes pas autorise a acceder au tableau de bord',
    super.originalError,
  ]);
}

/// Exception when dashboard data is in an invalid state
class DashboardDataException extends DashboardException {
  const DashboardDataException(super.message, [super.originalError]);

  /// Factory for invalid data format
  factory DashboardDataException.invalidFormat([dynamic error]) {
    return DashboardDataException(
      'Les donnees du tableau de bord sont dans un format invalide',
      error,
    );
  }

  /// Factory for missing required data
  factory DashboardDataException.missingData(String field, [dynamic error]) {
    return DashboardDataException(
      'Donnee manquante: $field',
      error,
    );
  }
}
