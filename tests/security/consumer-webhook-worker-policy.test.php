<?php
declare(strict_types=1);

$source=(string)file_get_contents(__DIR__.'/../../ops/consumer-jobs-worker.php');
if (!str_contains($source,"'iol.imatextil.com.br'=>['192.168.0.39']")) {
    throw new RuntimeException('approved private webhook destination is missing');
}
if (!str_contains($source,'curl_multi_init()') || !str_contains($source,'for($n=0;$n<10;$n++)')) {
    throw new RuntimeException('parallel worker fan-out must remain local and capped at ten');
}
if (str_contains($source,'$_GET') || str_contains($source,'php://input')) {
    throw new RuntimeException('private worker must not accept public request input');
}
if (!str_contains($source,"throw new RuntimeException('private destination')")) {
    throw new RuntimeException('private destination blocking is missing');
}
echo "PASS worker webhook destination policy\n";
