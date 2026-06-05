CATCH sistError AS Progress.Lang.SysError:    
    UNDO, THROW sistError.
END CATCH.


