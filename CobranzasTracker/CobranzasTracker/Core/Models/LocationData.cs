namespace CobranzasTracker.Core.Models;

public class LocationData
{
    #region Public Properties

    public string Accuracy { get; set; }

    // Precise or Approximate
    public int BatteryLevel { get; set; }

    public double Latitude { get; set; }

    public double Longitude { get; set; }

    public DateTime Timestamp { get; set; }

    public string Username { get; set; }

    #endregion Public Properties
}