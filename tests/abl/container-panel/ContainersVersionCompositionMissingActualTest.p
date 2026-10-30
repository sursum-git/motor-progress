/* Dedicated regression: generated versions may legitimately have no actual
   ERP cost. History must retain null through the second central snapshot. */
&SCOPED-DEFINE VERSION_COMPOSITION_MISSING_ACTUAL 1
{ContainersVersionCompositionTest.p}
DEFINE VARIABLE missingActualQuery AS HANDLE NO-UNDO.
DEFINE VARIABLE missingActualCount AS INTEGER NO-UNDO.
CREATE QUERY missingActualQuery. missingActualQuery:SET-BUFFERS(hb[14]).
missingActualQuery:QUERY-PREPARE("FOR EACH " + hb[14]:NAME + " WHERE " + hb[14]:NAME + ".item_container_id=2 NO-LOCK").
missingActualQuery:QUERY-OPEN(). missingActualQuery:GET-FIRST().
DO WHILE NOT missingActualQuery:QUERY-OFF-END:
 RUN Check(hb[14]:BUFFER-FIELD("vl_unit_realiz"):BUFFER-VALUE=?,"missing actual physically remains unknown, never zero").
 RUN Check(hb[14]:BUFFER-FIELD("vl_unit_prev"):BUFFER-VALUE<>?,"confirmed forecast persists independently of missing actual").
 missingActualCount=missingActualCount + 1. missingActualQuery:GET-NEXT().
END.
RUN Check(missingActualCount=2,"both initial and followup snapshots preserve the missing-actual item").
missingActualQuery:QUERY-CLOSE(). DELETE OBJECT missingActualQuery.
OUTPUT TO VALUE("containers-version-missing-actual-tests-" + SESSION:NUMERIC-FORMAT + ".log").
PUT UNFORMATTED "PASS " checks " checks; two actual-null snapshots, no fabricated zero." SKIP. OUTPUT CLOSE.
