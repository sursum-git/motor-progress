{ prodict/fhidden.i }
{esp/util.i}

/*DEFINE TEMP-TABLE ttRelacs
    FIELD tb01      AS CHAR
    FIELD tb02      AS CHAR
    FIELD campos    AS CHAR .
 */  


//DEFINE OUTPUT PARAMETER TABLE FOR ttRelacs .
DEFINE VARIABLE cCampos AS CHARACTER   NO-UNDO.

/*MESSAGE 'oi'
    VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/

PROCEDURE inserirTtRelacs:
    DEFINE INPUT  PARAMETER pTb01 AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pTb02 AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pCps  AS CHARACTER   NO-UNDO.
    CREATE ttRelacs.
    ASSIGN ttRelacs.tb01 = pTb01
           ttRelacs.tb02 = pTb02
           ttRelacs.campos = pCps.

END PROCEDURE.

//DEFINE SHARED STREAM rpt.

DEFINE TEMP-TABLE g_relate NO-UNDO
  FIELD g_owner  LIKE _File._File-name
  FIELD g_member LIKE _File._File-name
  FIELD g_idx    LIKE _Index._Index-name.

DEFINE BUFFER g_mfile  FOR bdori._File.
DEFINE BUFFER g_xfield FOR bdori._Field.
DEFINE BUFFER g_xfile  FOR bdori._File.

DEFINE VARIABLE noway    AS LOGICAL NO-UNDO.
DEFINE VARIABLE line     AS CHAR    NO-UNDO.  


FOR EACH {1}.g_mfile NO-LOCK
  WHERE (IF {3} = "ALL" THEN (IF NOT fHidden THEN NOT _Hidden ELSE g_mfile._File-Number > 0)
                        ELSE g_mfile._File-name = {3}):
  IF INTEGER(DBVERSION({1})) > 8 AND
    (g_mfile._Owner <> "PUB" AND g_mfile._Owner <> "_FOREIGN") THEN NEXT.
    
  
  /* Clear work file */
  FOR EACH g_relate NO-LOCK: DELETE g_relate.  END.

  FOR
    EACH {2}._Index       WHERE _Unique,
    EACH {2}._File        OF _Index WHERE _File._File-num > 0,
    EACH {2}._Index-field OF _Index,
    EACH {2}._Field       OF _Index-field NO-LOCK:
    /*MESSAGE 'tb.' _file._file-name SKIP
            'campo' _Field._Field-name
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
    IF _Index-seq = 1 THEN
      FOR EACH g_xfield WHERE g_xfield._Field-name = _Field._Field-name
        AND RECID(g_xfield) <> RECID(_Field),
        EACH g_xfile OF g_xfield NO-LOCK:
        IF g_mfile._File-name <> _File._File-name
          AND g_mfile._File-name <> g_xfile._File-name THEN NEXT.
        CREATE g_relate.
        ASSIGN
          g_relate.g_owner  = _File._File-name
          g_relate.g_member = g_xfile._File-name
          g_relate.g_idx    = _Index._Index-name.
      END.
    ELSE
      FOR EACH g_relate
        WHERE g_idx = _Index._Index-name AND g_owner = _File._File-name,
        EACH g_xfile WHERE g_xfile._File-name = g_member NO-LOCK:
        IF NOT CAN-FIND(g_xfield OF g_xfile
          WHERE g_xfield._Field-name = _Field._Field-name) 
          AND available g_relate
          THEN DELETE g_relate.
      END.
  END.

  FOR EACH g_relate NO-LOCK BREAK BY g_owner BY g_member:
    IF NOT (FIRST-OF(g_member) AND LAST-OF(g_member)) THEN DELETE g_relate.
  END.

  
  FOR EACH g_relate NO-LOCK WHERE g_owner = g_mfile._File-name BY g_owner:
    
    FIND g_xfile NO-LOCK WHERE  g_xfile._File-name = g_owner
                           AND (g_xfile._Owner = "PUB" OR g_xfile._Owner = "_FOREIGN").
    FIND _Index OF g_xfile NO-LOCK WHERE _Index-name = g_idx.
    ASSIGN cCampos = ''.
    FOR EACH _Index-field OF _Index,EACH _Field OF _Index-field NO-LOCK:
        RUN incrValor(INPUT-OUTPUT cCampos,_field-name,",").
      
    END.
    
    /*MESSAGE g_member SKIP
            g_owner SKIP
            cCampos SKIP
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
    RUN inserirTtRelacs(g_member,g_owner, cCampos).
  END.

  FOR EACH g_relate NO-LOCK 
        WHERE g_member = g_mfile._File-name BY g_member:
    line = "  " + g_member + " OF " + g_owner + " ".
    FIND g_xfile NO-LOCK WHERE  g_xfile._File-name = g_owner
                           AND (g_xfile._Owner = "PUB" OR g_xfile._Owner = "_FOREIGN").
    FIND _Index OF g_xfile NO-LOCK WHERE _Index-name = g_idx.
    ASSIGN cCampos = ''.
    FOR EACH _Index-field OF _Index,EACH _Field OF _Index-field NO-LOCK:
      RUN incrValor(INPUT-OUTPUT cCampos,_field-name,",").
      
    END.
   
   /* MESSAGE g_member SKIP
            g_owner SKIP
            cCampos SKIP
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
    RUN inserirTtRelacs(g_member,g_owner, cCampos).
  END.
END.








