using Android;
using Android.App;
using Android.Content;
using Android.Content.PM;
using AndroidX.Core.App;
using AndroidX.Core.Content;

namespace CobranzasTracker.Platforms.Android;

public static class PermissionHelper
{
    #region Public Fields

    public static readonly string[] RequiredPermissions =
    {
        Manifest.Permission.AccessFineLocation,
        Manifest.Permission.AccessCoarseLocation,
        Manifest.Permission.ForegroundService,
        Manifest.Permission.ForegroundServiceLocation,
        Manifest.Permission.AccessBackgroundLocation
    };

    #endregion Public Fields

    #region Public Methods

    public static bool HasAllRequiredPermissions(Context context)
    {
        foreach (var permission in RequiredPermissions)
        {
            if (ContextCompat.CheckSelfPermission(context, permission) != (int)Permission.Granted)
            {
                return false;
            }
        }
        return true;
    }

    public static void RequestPermissions(Activity activity)
    {
        ActivityCompat.RequestPermissions(activity, RequiredPermissions, 1001);
    }

    public static bool ShouldShowRequestPermissionRationale(Activity activity, string permission)
    {
        return ActivityCompat.ShouldShowRequestPermissionRationale(activity, permission);
    }

    #endregion Public Methods
}