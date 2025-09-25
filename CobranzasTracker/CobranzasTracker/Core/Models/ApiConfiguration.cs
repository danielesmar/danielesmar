namespace CobranzasTracker.Core.Models;

public class ApiConfiguration
{
    #region Public Properties

    public TimeSpan EndTime { get; set; }

    public DateTime LastUpdated { get; set; }

    public TimeSpan StartTime { get; set; }

    public int UpdateIntervalMinutes { get; set; }

    #endregion Public Properties
}