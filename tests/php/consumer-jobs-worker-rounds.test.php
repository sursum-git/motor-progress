<?php
declare(strict_types=1);

require_once dirname(__DIR__, 2).'/ops/consumer-jobs-worker-lib.php';

function assertSameValue(mixed $expected,mixed $actual,string $message):void {
    if($expected!==$actual) throw new RuntimeException($message.' expected='.var_export($expected,true).' actual='.var_export($actual,true));
}

$sequence=[3,2,0,7];$calls=0;
$total=workerRunDrainRounds(static function()use(&$sequence,&$calls):int{$calls++;return array_shift($sequence);},5);
assertSameValue(5,$total,'stops after the first empty round');
assertSameValue(3,$calls,'does not dispatch after an empty round');

$sequence=[1,1,1,1];$calls=0;
$total=workerRunDrainRounds(static function()use(&$sequence,&$calls):int{$calls++;return array_shift($sequence);},3);
assertSameValue(3,$total,'caps productive dispatch rounds');
assertSameValue(3,$calls,'honors the configured round cap');

echo "PASS worker drain rounds\n";
