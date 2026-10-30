/* ? representa limite aberto; texto vazio tambem. Zero numerico e um limite real. */
IF pcEstabelDe = ? THEN pcEstabelDe = "".
IF pcEstabelAte = ? THEN pcEstabelAte = "".
IF pcNotaDe = ? THEN pcNotaDe = "".
IF pcNotaAte = ? THEN pcNotaAte = "".
IF pcPedidoDe = ? THEN pcPedidoDe = "".
IF pcPedidoAte = ? THEN pcPedidoAte = "".
IF (pcEstabelDe <> "" AND pcEstabelAte <> "" AND pcEstabelDe > pcEstabelAte)
OR (piClienteDe <> ? AND piClienteAte <> ? AND piClienteDe > piClienteAte)
OR (pcNotaDe <> "" AND pcNotaAte <> "" AND pcNotaDe > pcNotaAte)
OR (pcPedidoDe <> "" AND pcPedidoAte <> "" AND pcPedidoDe > pcPedidoAte)
OR (piRepresentanteDe <> ? AND piRepresentanteAte <> ? AND piRepresentanteDe > piRepresentanteAte)
OR (pdEmissaoDe <> ? AND pdEmissaoAte <> ? AND pdEmissaoDe > pdEmissaoAte) THEN
    UNDO, THROW NEW Progress.Lang.AppError("Faixa invalida: de maior que ate", 1).

