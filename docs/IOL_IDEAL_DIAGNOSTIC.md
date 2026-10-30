# Divergência do Ideal Loja — 19/10/2026

**Causa identificada: o cartão PHP exibe zero fixo e ignora o percentual que o próprio programa calcula.** A API usa o resultado da fórmula de dias úteis. A divergência observada de PHP0% / API52% é, portanto, explicada por esse defeito de apresentação no PHP; não se deve substituir o cálculo da API por zero para reproduzi-lo.

## Evidência no fonte

Fonte coletado anteriormente do Scriptcase: `sources/scriptcase/iol/bl_pag_ini_ger/index.php`.

Linhas6291–6299 calculam:

```php
$metaIdeal = $metaVendedores / $qtDiasMes * $qtDias;
if ($metaVendedores <> 0) {
    $percMetaIdeal = round($metaIdeal / $metaVendedores * 100, 0);
} else {
    $percMetaIdeal = 0;
}
```

Para meta não zero e calendário válido, equivale a `round(dias úteis passados / dias úteis do mês * 100, 0)`.

Entretanto, no HTML do cartão, linhas6942–6946, o resultado não é usado:

```html
<span class="meta-label">% Ideal</span>
<div class="progress-bar small">
    <div class="progress-fill" style="width: 0%"></div>
</div>
<span class="meta-value">0%</span>
```

Na API, `IolGerencialCalculator.p:73` calcula `ROUND(dElapsed / dDays * 100,0)` quando a meta da loja é diferente de zero, e a linha74 preenche `percentual_loja_ideal`. O coletor seleciona o calendário `calend_global`, exige `log_dia_util=TRUE`, exclui sábado/domingo e inclui o dia de referência entre os passados. O PHP também prevê essa regra em `diasUteisMes` e `getUtilizDiaCalend`.

## Reprodução atual

O navegador recarregou o PHP original em19/10/2026. O menu confirmou **TASILPAR**; o cartão expandido continuou em **0%**, com estilo DOM `width: 0%`. A página mostrou nove dias úteis restantes. Evidência visual privada: `.runtime/iol-ideal-20261019/php-ideal-zero.png`. Nenhum valor financeiro foi necessário para concluir o diagnóstico.

O painel da API estava com o resultado antigo52% na aba; ao clicar Atualizar, a consulta retornou `Falha ao consultar a API externa`. As novas conexões SSH ao Scriptcase `.170` e PASOE `.111` também expiraram. Portanto, **52% é a observação anterior de17/10, não uma nova medição de19/10**. Não foi possível confirmar agora as contagens atuais de calendário ou o valor corrente retornado pela API. A cópia atualizada do fonte remoto também não pôde ser conferida por SSH; a reprodução pelo PHP público confirmou a apresentação0%.

## Correção indicada

Usar no cartão PHP as variáveis que já são calculadas:

```php
<div class="progress-fill" style="width: <?php echo $percMetaIdealFormat; ?>"></div>
<span class="meta-value"><?php echo $percMetaIdeal; ?>%</span>
```

O patch de duas linhas está preparado em `integration-src/iol-pagina-inicial-gerencial/ideal-loja-php-display.patch`, aplicado somente ao bloco identificado. Deve ser levado ao evento/template de origem no Scriptcase para não ser perdido numa geração posterior. Não se deve aplicar uma substituição global de `0%`.

**Esta entrega é diagnóstico: nenhum fonte de produção, fórmula da API, parâmetro ou dado de negócio foi alterado.** A validação do valor atual da API permanece dependente da integração voltar a responder.
