namespace CobranzasTracker.Infrastructure.Services;

public class AuthService : IAuthService
{
    #region Private Fields
    private const string AuthKey = "user_auth_data";
    private readonly ISecureStorageService _secureStorage;

    #endregion Private Fields

    #region Public Constructors

    public AuthService(ISecureStorageService secureStorage)
    {
        _secureStorage = secureStorage;
    }

    #endregion Public Constructors

    #region Public Events

    public event EventHandler AuthenticationStateChanged;

    #endregion Public Events

    #region Public Methods

    // Método para verificar y renovar token si es necesario
    public async Task<bool> CheckAndRenewTokenAsync()
    {
        var user = await _secureStorage.GetAsync<User>(AuthKey);
        if (user == null) return false;

        // Si el token expira en menos de 1 día, renovarlo
        if (user.ExpirationTime < DateTime.UtcNow.AddDays(1))
        {
            user.ExpirationTime = DateTime.UtcNow.AddDays(30);
            await _secureStorage.SaveAsync(AuthKey, user);
        }

        return user.IsLoggedIn;
    }

    public string GetCurrentUser()
    {
        var user = _secureStorage.GetAsync<User>(AuthKey).Result;
        return user?.Username ?? string.Empty;
    }

    public bool IsUserLoggedIn()
    {
        var user = _secureStorage.GetAsync<User>(AuthKey).Result;

        // Verificar si existe el usuario Y si la sesión sigue válida
        return user != null && user.IsLoggedIn && user.ExpirationTime > DateTime.UtcNow;
    }

    public async Task<bool> LoginAsync(string username, string password)
    {
        await Task.Delay(1000); // Simulate API call

        // Mock authentication - en producción esto vendría de una API
        if ((username == "admin" && password == "password123") ||
            (username == "user" && password == "test123"))
        {
            var user = new User
            {
                Username = username,
                Token = Guid.NewGuid().ToString(),
                IsLoggedIn = true,
                LoginTime = DateTime.UtcNow,
                ExpirationTime = DateTime.UtcNow.AddDays(30) // Token válido por 30 días
            };

            await _secureStorage.SaveAsync(AuthKey, user);
            AuthenticationStateChanged?.Invoke(this, EventArgs.Empty);
            return true;
        }

        return false;
    }

    public async Task<bool> LogoutAsync()
    {
        await _secureStorage.RemoveAsync(AuthKey);
        AuthenticationStateChanged?.Invoke(this, EventArgs.Empty);
        return true;
    }

    #endregion Public Methods
}