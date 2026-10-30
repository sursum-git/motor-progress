/* Isolated local test database only; never run against a connected ERP database. */
IF NUM-DBS<>1 OR INDEX(PDBNAME(1),"aggregate-fixture")=0 THEN RETURN ERROR "FIXTURE_DATABASE_REQUIRED".
RUN prodict/load_df.p("aggregate-fixture.df").
QUIT.
