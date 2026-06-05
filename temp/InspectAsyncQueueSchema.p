PROPATH = "D:\opencode\motor-progress\sursum,D:\opencode\motor-progress\sursum\esp,D:\opencode\motor-progress," + PROPATH.

FOR EACH DICTDB._File NO-LOCK
    WHERE DICTDB._File._File-Name = "SursumQueryJob"
       OR DICTDB._File._File-Name = "SursumQueryJobEvent":

    MESSAGE "TABLE=" + DICTDB._File._File-Name.

    FOR EACH DICTDB._Field NO-LOCK
        WHERE DICTDB._Field._File-Recid = RECID(DICTDB._File)
        BY DICTDB._Field._Order:
        MESSAGE "FIELD=" + DICTDB._Field._Field-Name.
        MESSAGE "TYPE=" + DICTDB._Field._Data-Type.
        MESSAGE "INITIAL=" + (IF DICTDB._Field._Initial = ? THEN "<unknown>" ELSE STRING(DICTDB._Field._Initial)).
    END.
END.

QUIT.
