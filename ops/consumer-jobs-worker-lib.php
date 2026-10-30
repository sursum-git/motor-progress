<?php
declare(strict_types=1);

/**
 * Refill an owned, private worker cycle without allowing it to run forever.
 * The PASOE response remains the only signal that work was claimed.
 */
function workerRunDrainRounds(callable $drainBatch,int $maximumRounds=5):int
{
    if($maximumRounds<1||$maximumRounds>20)throw new InvalidArgumentException('invalid worker round limit');
    $processed=0;
    for($round=0;$round<$maximumRounds;$round++){
        $roundProcessed=$drainBatch();
        if($roundProcessed<0)throw new RuntimeException('invalid processed count');
        $processed+=$roundProcessed;
        if($roundProcessed===0)break;
    }
    return $processed;
}
