O projecto usa o nodejs e está escrito em coffeescript.

http://nodejs.org/
http://coffeescript.org/

O coffeescript pode ser instalado no Ubuntu com: sudo apt-get install coffeescript
Em qualquer plataforma onde o nodejs esteja instalado com: npm install -g coffee-script
usando o sudo, se aplicável.


Para comprimir, usa-se:

coffee deflate.coffee filename

O que produz um ficheiro com extensão .deflate

Para comprimir, usa-se_
coffee inflate.coffee filename.deflate

O que produz um ficheiro com a extensão .deflate.inflate

Assim, podem-se comparar os ficheiros com:

diff filename.deflate.inflate filename

Nos ficheiros de texto testados, o rácio de compressão está pouco abaixo dos 50%.
Nos bmps, entre 1% e 10%, o que é francamente melhor (estou a calcular o rácio com : comprimido/original).


Acredito que seria possível obter melhores taxas nos ficheiros grandes, se o algoritmo tomasse melhores decisões.

Do nodejs apenas são usados os métodos "require" para importar os módulos e, no caso dos ficheiros cli (inflate e deflate), os métodos de acesso aos ficheiros.

Todos os algoritmos usam javascript puro, apenas é usado adicionalemnte o Uint8Array, que existe no nodejs e em todos os browsers modernos (é usado no webgl).