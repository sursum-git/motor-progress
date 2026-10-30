/* Private, stateless policy provider. Each callback reads IMA directly. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
{sursum-api/includes/parametros_ima.i}
{sursum-api/includes/ContainerCustoBoundary.i}
{sursum-api/includes/ContainerFinancePolicy.i}
{ContainersVersionContextBody.i}
