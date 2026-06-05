output to "c:\temp\prgapagarwp.log" append.

put substring(string(now),01,10)           format "x(10)" " as "
    substring(string(now),12,10)           format "x(08)" " - "
	"Apagando registro da tabela wp" format "x(51)"
    skip.
for each wp exclusive-lock:
    delete wp.
end.

put substring(string(now),01,10)                     format "x(10)" " as "
    substring(string(now),12,10)                     format "x(08)" " - "
    "Apagando registro da tabela wp_ped_venda" format "x(51)"
    skip.
for each wp_ped_venda exclusive-lock:
    delete wp_ped_venda.
end.

put substring(string(now),01,10)					   format "x(10)" " as "
    substring(string(now),12,10)					   format "x(08)" " - "
    "Apagando registro da tabela wp_nota_fiscal" format "x(51)"
    skip.
for each wp_nota_fiscal exclusive-lock:
    delete wp_nota_fiscal.
end.

put substring(string(now),01,10)						 format "x(10)" " as "
    substring(string(now),12,10)						 format "x(08)" " - "
	"Apagando registro da tabela wp_estoque_preco" format "x(51)"
    skip.
for each wp_estoque_preco exclusive-lock:
    delete wp_estoque_preco.
end.

put substring(string(now),01,10)						 format "x(10)" " as "
    substring(string(now),12,10)						 format "x(08)" " - "
	"--------------------------------------------------" format "x(51)"
    skip.

output close.
