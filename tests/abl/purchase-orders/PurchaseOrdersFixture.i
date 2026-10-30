/* Undoable isolated fixtures; never publish. */
{ContainersItensFinanceiroFixture.i}
DEFINE TEMP-TABLE ttCompanies FIELD empresa_id AS INTEGER FIELD cod_emp_ems2 AS INTEGER FIELD cod_emp_ems5 AS INTEGER INDEX pk IS UNIQUE PRIMARY empresa_id.
DEFINE TEMP-TABLE ttSuppliers FIELD cod-emitente AS INTEGER INDEX pk IS UNIQUE PRIMARY cod-emitente.
DEFINE TEMP-TABLE ttDependencies FIELD dependency_id AS INTEGER FIELD proc_compra_id AS INTEGER INDEX pk IS UNIQUE PRIMARY dependency_id.
