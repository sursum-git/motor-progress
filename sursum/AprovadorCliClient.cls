USING Arquivo.Arquivo.
USING Arquivo.LerArquivoConfig.
USING Progress.Lang.Error.

class AprovadorCliClient:

    /* Wrapper do Aprovador CLI para ERP legado.
       Recomenda-se distribuir 1 executÇ­vel por SO:
       - Windows: C:\AprovadorCLI\aprovador-cli-win-amd64.exe
       - Linux: /opt/aprovador-cli/aprovador-cli-linux-amd64
       - macOS: /opt/aprovador-cli/aprovador-cli-darwin-arm64

       Comandos disponÇðveis: create, batch, consultar, cancelar, status.
    */

    define public property ExecutablePath as character
        get.
        set.

    define public property ApiUrl as character
        get.
        set.

    define public property ApiKey as character
        get.
        set.

    define public property RetryMax as integer
        get.
        set.

    define public property RetryDelayMs as integer
        get.
        set.

    define public property TimeoutMs as integer
        get.
        set.

    define public property DefaultOutput as character
        get.
        set.

    constructor public AprovadorCliClient():
        this-object:ExecutablePath = "aprovador-cli".
        this-object:RetryMax = 3.
        this-object:RetryDelayMs = 500.
        this-object:TimeoutMs = 30000.
        this-object:DefaultOutput = "json".
    end constructor.

    constructor public AprovadorCliClient(
        input pcExecutable as character,
        input pcApiUrl as character,
        input pcApiKey as character
    ):
        this-object:ExecutablePath = pcExecutable.
        this-object:ApiUrl = pcApiUrl.
        this-object:ApiKey = pcApiKey.

        this-object:RetryMax = 3.
        this-object:RetryDelayMs = 500.
        this-object:TimeoutMs = 30000.
        this-object:DefaultOutput = "json".
    end constructor.

    method public void SetConnection(
        input pcApiUrl as character,
        input pcApiKey as character
    ):
        this-object:ApiUrl = pcApiUrl.
        this-object:ApiKey = pcApiKey.
    end method.

    method public void SetRetry(
        input piRetryMax as integer,
        input piRetryDelayMs as integer,
        input piTimeoutMs as integer
    ):
        this-object:RetryMax = NormalizeRetryMax(piRetryMax).
        this-object:RetryDelayMs = NormalizePositiveInteger(piRetryDelayMs, 500).
        this-object:TimeoutMs = NormalizePositiveInteger(piTimeoutMs, 30000).
    end method.

    method public logical Create(
        input pcSistema as character,
        input pcTipo as character,
        input pcReferencia as character,
        input pcTitulo as character,
        input pcChaveIdempotencia as character,
        input pcDescricao as character,
        input pcPrioridade as character,
        input pcPayload as longchar,
        input pcSolicitante as longchar,
        input pcChaveNegocio as longchar,
        input pcSchemaVisual as longchar,
        input plDryRun as logical,
        output pcResponse as longchar,
        output piExitCode as integer
    ):
        define variable cArgs as character no-undo.

        cArgs = BuildCreateArgs(
            pcSistema,
            pcTipo,
            pcReferencia,
            pcTitulo,
            pcChaveIdempotencia,
            pcDescricao,
            pcPrioridade,
            pcPayload,
            "",
            pcSolicitante,
            pcChaveNegocio,
            pcSchemaVisual,
            plDryRun
        ).

        return Invoke(cArgs, pcResponse, piExitCode).
    end method.

    method public logical CreateWithPayloadFile(
        input pcSistema as character,
        input pcTipo as character,
        input pcReferencia as character,
        input pcTitulo as character,
        input pcChaveIdempotencia as character,
        input pcDescricao as character,
        input pcPrioridade as character,
        input pcPayloadFile as character,
        input pcSolicitante as longchar,
        input pcChaveNegocio as longchar,
        input pcSchemaVisual as longchar,
        input plDryRun as logical,
        output pcResponse as longchar,
        output piExitCode as integer
    ):
        define variable cArgs as character no-undo.

        cArgs = BuildCreateArgs(
            pcSistema,
            pcTipo,
            pcReferencia,
            pcTitulo,
            pcChaveIdempotencia,
            pcDescricao,
            pcPrioridade,
            ?,
            pcPayloadFile,
            pcSolicitante,
            pcChaveNegocio,
            pcSchemaVisual,
            plDryRun
        ).

        return Invoke(cArgs, pcResponse, piExitCode).
    end method.

    method public logical Consultar(
        input pcSistema as character,
        input pcReferencia as character,
        output pcResponse as longchar,
        output piExitCode as integer
    ):
        define variable cArgs as character no-undo.

        cArgs = "consultar".
        cArgs = cArgs + " --api-url "           + EscapeArg(this-object:ApiUrl).
        cArgs = cArgs + " --api-key "           + EscapeArg(this-object:ApiKey).
        cArgs = cArgs + " --retry-max "         + STRING(NormalizeRetryMax(this-object:RetryMax)).
        cArgs = cArgs + " --retry-delay-ms "    + STRING(NormalizePositiveInteger(this-object:RetryDelayMs, 500)).
        cArgs = cArgs + " --timeout-ms "        + STRING(NormalizePositiveInteger(this-object:TimeoutMs, 30000)).
        cArgs = cArgs + " --output "            + this-object:DefaultOutput.
        cArgs = cArgs + " --sistema "           + EscapeArg(pcSistema).
        cArgs = cArgs + " --referencia "        + EscapeArg(pcReferencia).

        return Invoke(cArgs, pcResponse, piExitCode).
    end method.

    method public logical Cancelar(
        input pcId as character,
        output pcResponse as longchar,
        output piExitCode as integer
    ):
        define variable cArgs as character no-undo.

        cArgs = "cancelar".
        cArgs = cArgs + " --api-url " + EscapeArg(this-object:ApiUrl).
        cArgs = cArgs + " --api-key " + EscapeArg(this-object:ApiKey).
        cArgs = cArgs + " --retry-max " + STRING(NormalizeRetryMax(this-object:RetryMax)).
        cArgs = cArgs + " --retry-delay-ms " + STRING(NormalizePositiveInteger(this-object:RetryDelayMs, 500)).
        cArgs = cArgs + " --timeout-ms " + STRING(NormalizePositiveInteger(this-object:TimeoutMs, 30000)).
        cArgs = cArgs + " --output " + this-object:DefaultOutput.
        cArgs = cArgs + " --id " + EscapeArg(pcId).

        return Invoke(cArgs, pcResponse, piExitCode).
    end method.

    method public logical Status(
        output pcResponse as longchar,
        output piExitCode as integer
    ):
        define variable cArgs as character no-undo.

        cArgs = "status".
        cArgs = cArgs + " --api-url " + EscapeArg(this-object:ApiUrl).
        cArgs = cArgs + " --api-key " + EscapeArg(this-object:ApiKey).
        cArgs = cArgs + " --retry-max " + STRING(NormalizeRetryMax(this-object:RetryMax)).
        cArgs = cArgs + " --retry-delay-ms " + STRING(NormalizePositiveInteger(this-object:RetryDelayMs, 500)).
        cArgs = cArgs + " --timeout-ms " + STRING(NormalizePositiveInteger(this-object:TimeoutMs, 30000)).
        cArgs = cArgs + " --output " + this-object:DefaultOutput.

        return Invoke(cArgs, pcResponse, piExitCode).
    end method.

    method public logical Batch(
        input pcInputFile as character,
        input pcFormato as character,
        input pcOutput as character,
        output pcResponse as longchar,
        output piExitCode as integer
    ):
        define variable cArgs as character no-undo.
        define variable cEffectiveOutput as character no-undo.

        cArgs = "batch".
        cArgs = cArgs + " --api-url " + EscapeArg(this-object:ApiUrl).
        cArgs = cArgs + " --api-key " + EscapeArg(this-object:ApiKey).
        cArgs = cArgs + " --retry-max " + STRING(NormalizeRetryMax(this-object:RetryMax)).
        cArgs = cArgs + " --retry-delay-ms " + STRING(NormalizePositiveInteger(this-object:RetryDelayMs, 500)).
        cArgs = cArgs + " --timeout-ms " + STRING(NormalizePositiveInteger(this-object:TimeoutMs, 30000)).

        if pcFormato <> "" then
            cArgs = cArgs + " --format " + EscapeArg(pcFormato).

        cEffectiveOutput = if (pcOutput <> "") then pcOutput else this-object:DefaultOutput.
        cArgs = cArgs + " --output " + EscapeArg(cEffectiveOutput).
        cArgs = cArgs + " --input " + EscapeArg(pcInputFile).

        return Invoke(cArgs, pcResponse, piExitCode).
    end method.

    method private logical Invoke(
        input pcArgs as character,
        output pcResponse as longchar,
        output piExitCode as integer
    ):
        define variable cLine as character no-undo.
        define variable cCmd as character no-undo.

        pcResponse = "".
        piExitCode = 0.

        if this-object:ExecutablePath = "" then do:
            pcResponse = "ExecutablePath nao configurado.".
            piExitCode = -1.
            return false.
        end.

        cCmd = EscapeArg(this-object:ExecutablePath) + " " + pcArgs.
        input THROUGH cCmd NO-ERROR.
        if error-status:error then do:
            pcResponse = "Erro ao iniciar CLI: " + error-status:get-message(1).
            piExitCode = -1.
            return false.
        end.

        repeat:
            import unformatted cLine no-error.
            if error-status:error then
                leave.
            pcResponse = pcResponse + cLine + CHR(10).
        end.

        input CLOSE.

        return true.
    end method.

    method private character EscapeArg(input pcValue as character):
        define variable cEscaped as character no-undo.
        define variable cFinal as character no-undo.

        if pcValue = ? or pcValue = "" then
            return '""'.

        cEscaped = replace(pcValue, chr(34), chr(92) + CHR(34)).
        cFinal = substitute('"~A"', cEscaped).
        return cFinal.
    end method.

    method private character BuildCreateArgs(
        input pcSistema as character,
        input pcTipo as character,
        input pcReferencia as character,
        input pcTitulo as character,
        input pcChaveIdempotencia as character,
        input pcDescricao as character,
        input pcPrioridade as character,
        input pcPayload as longchar,
        input pcPayloadFile as character,
        input pcSolicitante as longchar,
        input pcChaveNegocio as longchar,
        input pcSchemaVisual as longchar,
        input plDryRun as logical
    ):
        define variable cArgs as character no-undo.
        define variable cPayload as character no-undo.
        define variable cFilePayload as character no-undo.

        cArgs = "create".
        cArgs = cArgs + " --api-url " + EscapeArg(this-object:ApiUrl).
        cArgs = cArgs + " --api-key " + EscapeArg(this-object:ApiKey).
        cArgs = cArgs + " --retry-max " + STRING(NormalizeRetryMax(this-object:RetryMax)).
        cArgs = cArgs + " --retry-delay-ms " + STRING(NormalizePositiveInteger(this-object:RetryDelayMs, 500)).
        cArgs = cArgs + " --timeout-ms " + STRING(NormalizePositiveInteger(this-object:TimeoutMs, 30000)).
        cArgs = cArgs + " --output " + this-object:DefaultOutput.

        cArgs = cArgs + " --sistema " + EscapeArg(pcSistema).
        cArgs = cArgs + " --tipo " + EscapeArg(pcTipo).
        cArgs = cArgs + " --referencia " + EscapeArg(pcReferencia).
        cArgs = cArgs + " --titulo " + EscapeArg(pcTitulo).

        if pcChaveIdempotencia <> "" then
            cArgs = cArgs + " --chave-idempotencia " + EscapeArg(pcChaveIdempotencia).
        if pcDescricao <> "" then
            cArgs = cArgs + " --descricao " + EscapeArg(pcDescricao).
        if pcPrioridade <> "" then
            cArgs = cArgs + " --prioridade " + EscapeArg(pcPrioridade).

        cFilePayload = trim(pcPayloadFile).
        cPayload = string(pcPayload).

        if cFilePayload <> "" then
            cArgs = cArgs + " --payload-file " + EscapeArg(cFilePayload).
        else if pcPayload <> ? and TRIM(cPayload) <> "" then
            cArgs = cArgs + " --payload " + EscapeArg(cPayload).

        if pcSolicitante <> ? then
            cArgs = cArgs + " --solicitante " + EscapeArg(string(pcSolicitante)).
        if pcChaveNegocio <> ? then
            cArgs = cArgs + " --chave-negocio " + EscapeArg(string(pcChaveNegocio)).
        if pcSchemaVisual <> ? then
            cArgs = cArgs + " --schema-visual " + EscapeArg(string(pcSchemaVisual)).
        if plDryRun then
            cArgs = cArgs + " --dry-run".

        return cArgs.
    end method.

    method private integer NormalizeRetryMax(input piRetryMax as integer):
        return MAX(0, piRetryMax).
    end method.

    method private integer NormalizePositiveInteger(input piValue as integer, input piDefault as integer):
        return if (piValue > 0) then piValue else piDefault.
    end method.

    method public logical LoadConfigFromFile(
        input pcArquivoConfig as character,
        input pcSessao as character
    ):
        define variable loArquivo as Arquivo.Arquivo NO-UNDO.
        define variable loConfig as Arquivo.LerArquivoConfig NO-UNDO.
        define variable lcSessao as character no-undo.
        define variable lcValor as character no-undo.
        define variable liValor as integer no-undo.

        lcSessao = if (pcSessao <> "" and pcSessao <> ?) then pcSessao else "APROVADOR_CLI".

        
        loArquivo = NEW Arquivo().
        loArquivo:setNomeArquivo(pcArquivoConfig, true).

        loConfig = new Arquivo.LerArquivoConfig().
        loConfig:arquivo = loArquivo.
        loConfig:separador = "=".
        loConfig:identificadorSessao = "[".
        loConfig:ler().

        lcValor = loConfig:getVlSessaoChave(lcSessao, "ExecutablePath").
        if lcValor <> ? and trim(lcValor) <> "" then
            this-object:ExecutablePath = lcValor.

        lcValor = loConfig:getVlSessaoChave(lcSessao, "ApiUrl").
        if lcValor <> ? and trim(lcValor) <> "" then
            this-object:ApiUrl = lcValor.

        lcValor = loConfig:getVlSessaoChave(lcSessao, "ApiKey").
        if lcValor <> ? and trim(lcValor) <> "" then
            this-object:ApiKey = lcValor.

        lcValor = loConfig:getVlSessaoChave(lcSessao, "DefaultOutput").
        if lcValor <> ? and trim(lcValor) <> "" then
            this-object:DefaultOutput = lcValor.

        liValor = ParseIntConfig(
            loConfig:getVlSessaoChave(lcSessao, "RetryMax"),
            this-object:RetryMax
        ).
        this-object:RetryMax = liValor.

        liValor = ParseIntConfig(
            loConfig:getVlSessaoChave(lcSessao, "RetryDelayMs"),
            this-object:RetryDelayMs
        ).
        this-object:RetryDelayMs = liValor.

        liValor = ParseIntConfig(
            loConfig:getVlSessaoChave(lcSessao, "TimeoutMs"),
            this-object:TimeoutMs
        ).
        this-object:TimeoutMs = liValor.

        return true.
        catch e as Progress.Lang.Error:
            return false.
        end catch.
    end method.

    method private integer ParseIntConfig(
        input pcValor as character,
        input piDefault as integer
    ):
        define variable liValor as integer no-undo.
        if pcValor = ? or trim(pcValor) = "" then
            return piDefault.

        liValor = integer(pcValor) no-error.
        if error-status:error then
            return piDefault.

        return liValor.
    end method.

end class.
