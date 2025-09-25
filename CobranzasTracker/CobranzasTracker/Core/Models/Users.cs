namespace CobranzasTracker.Core.Models;

public class User
{
    #region Public Properties

    public DateTime ExpirationTime { get; set; }

    public bool IsLoggedIn { get; set; }

    public DateTime LoginTime { get; set; }

    public string Password { get; set; }

    public string Token { get; set; }

    public string Username { get; set; }

    #endregion Public Properties
    // Nueva propiedad
}