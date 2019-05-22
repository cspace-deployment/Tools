import sys
import re
import urllib.parse

for musnos in sys.stdin.readlines():

    (sortNum, original) = musnos.strip().split('\t')
    match = re.match(r'^([0-9a-zA-Z]+)-(.*)', original)
    if match is None:
        #ARK = urllib.parse.quote('x' + original).replace('-','%2D').replace('.','%2E')
        ARK = urllib.parse.quote('x' + original).replace('-','%2D').replace('.','@')
    else:
        left, right = match.group(1), match.group(2)
        #ARK = urllib.parse.quote(left.zfill(3) + right.zfill(7)).replace('-','%2D').replace('.','%2E')
        ARK = urllib.parse.quote('1' + left.zfill(2) + right.zfill(7)).replace('-','%2D').replace('.','@')

    # reverse the "arkification"
    unARK = urllib.parse.unquote(ARK).replace('@','.')
    if unARK[0] == 'x':
        unARK = unARK[1:]
    else:
        left, right = unARK[1:3], unARK[3:]
        left = left.lstrip('0')
        right = right.lstrip('0')
        unARK = left + '-' + right

    # check if the reverse worked...
    reversible = '' if original == unARK else 'not reversible'

    print(f'%s\t%s\t%s\t%s' % (original, ARK, unARK, reversible))
