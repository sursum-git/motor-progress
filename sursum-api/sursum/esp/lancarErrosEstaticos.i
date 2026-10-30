CATCH sistError AS Progress.Lang.SysError:
    Comum.RegistrarErro:incluirErro(sistError:GetMessageNum(1), sistError:GetMessage(1)).
END CATCH.


CATCH appError AS Progress.Lang.AppError:
   Comum.RegistrarErro:incluirErro(appError:GetMessageNum(1), appError:GetMessage(1)).
END CATCH.