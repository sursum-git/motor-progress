<?php
$path = '/var/www/clients/client1/web7/web/sc98/app/ImaOnLine/cons_item_estoque_unificado/cons_item_estoque_unificado_grid.class.php';
$data = file_get_contents($path);
if ($data === false) {
    fwrite(STDERR, "failed to read\n");
    exit(1);
}

$start = strpos($data, '$acoes =' . "\n");
if ($start === false) {
    fwrite(STDERR, "start marker not found\n");
    exit(1);
}

$endMarker = "if (\n    \$scCardPlain(\$this->pdf_pi ) !== ''\n) {";
$end = strpos($data, $endMarker, $start);
if ($end === false) {
    fwrite(STDERR, "end marker not found\n");
    exit(1);
}

$replacement =
    '$acoes =' . "\n" .
    "    '<a ' .\n" .
    "        'href=\"' . \$scCardEscape(\$urlEstoque) . '\" ' .\n" .
    "        'class=\"sc-product-card__action\" ' .\n" .
    "        'onclick=\"' .\n" .
    "            'event.stopPropagation();' .\n" .
    "        '\">' .\n" .
    "        'PE + PI' .\n" .
    "    '</a>' .\n" .
    "    '<a ' .\n" .
    "        'href=\"' . \$scCardEscape(\$urlBookPe) . '\" ' .\n" .
    "        'target=\"_blank\" ' .\n" .
    "        'rel=\"noopener\" ' .\n" .
    "        'class=\"sc-product-card__action\" ' .\n" .
    "        'onclick=\"' .\n" .
    "            'event.stopPropagation();' .\n" .
    "        '\">' .\n" .
    "        'Book PE' .\n" .
    "    '</a>';\n";

$data = substr($data, 0, $start) . $replacement . substr($data, $end);
if (file_put_contents($path, $data) === false) {
    fwrite(STDERR, "failed to write\n");
    exit(1);
}
echo "patched\n";
