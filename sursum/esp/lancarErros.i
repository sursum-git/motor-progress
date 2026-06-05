CATCH sistError AS Progress.Lang.SysError:    
    UNDO, THROW sistError.
END CATCH.


CATCH appError AS Progress.Lang.AppError:
   UNDO, THROW AppError.
END CATCH.
