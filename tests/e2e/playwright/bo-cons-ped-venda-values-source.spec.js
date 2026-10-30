const fs = require('node:fs');
const { test, expect } = require('@playwright/test');

test('boConsPedVenda2 implementa o calculo de valores do pedido', () => {
  const source = fs.readFileSync('especificos/ems2/ima/esbo/boConsPedVenda2.p', 'utf8');
  expect(source).not.toContain('PROCEDURE _calcValoresPedido.\r\n     //TODO\r\nEND PROCEDURE.');
});
