using System.Globalization;

namespace CobranzasTracker.Converters;

public class MonitoringButtonTextConverter : IValueConverter
{
    #region Public Methods

    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        if (value is bool isMonitoring)
        {
            return isMonitoring ? "Stop Monitoring" : "Start Monitoring";
        }
        return "Start Monitoring";
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }

    #endregion Public Methods
}