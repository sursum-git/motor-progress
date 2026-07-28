<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);

$html = (string) file_get_contents($root . '/web/query-wizard-3steps.html');
assertContains($html, 'query-wizard-3steps.css', 'pagina referencia CSS proprio');

$cssPath = $root . '/web/query-wizard-3steps.css';
if (!is_file($cssPath)) {
    throw new RuntimeException('CSS da consulta por tabela nao existe.');
}
$css = (string) file_get_contents($cssPath);
assertContains($css, '.qw-shell', 'layout principal');
assertContains($css, '.qw-hero', 'cabecalho da tela');
assertContains($css, '.step-nav', 'navegacao das etapas');
assertContains($css, '.step-workspace', 'area das etapas');
assertContains($css, '.panel.is-active', 'exibe apenas etapa ativa');
assertContains($css, '.step-footer', 'rodape de navegacao');
assertContains($css, '@media', 'layout responsivo');

echo "Query wizard layout contract OK\n";

function assertContains(string $content, string $needle, string $label): void
{
    if (strpos($content, $needle) === false) {
        throw new RuntimeException($label . ': trecho nao encontrado: ' . $needle);
    }
}
