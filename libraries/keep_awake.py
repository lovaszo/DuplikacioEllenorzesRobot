

import ctypes

# Windows API konstansok
ES_CONTINUOUS       = 0x80000000
ES_SYSTEM_REQUIRED  = 0x00000001
ES_DISPLAY_REQUIRED = 0x00000002

def prevent_sleep():
    """
    Prevent Sleep kulcsszó: Megakadályozza a gép alvását és a kijelző kikapcsolását.
    """
    ctypes.windll.kernel32.SetThreadExecutionState(
        ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED
    )

def allow_sleep():
    """
    Allow Sleep kulcsszó: Visszaállítja az alap beállítást (engedélyezi az alvást).
    """
    ctypes.windll.kernel32.SetThreadExecutionState(ES_CONTINUOUS)
