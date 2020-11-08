# Extended GCD
def egcd(a, b):
    s0, s1, t0, t1 = 1, 0, 0, 1
    while b > 0:
        q, r = divmod(a, b)
        a, b = b, r
        s0, s1, t0, t1 = s1, s0 - q * s1, t1, t0 - q * t1
        pass
    return s0, t0, a

# Get invert element
def inv(n, q):
    # div on ç a/b mod q as a * inv(b, q) mod q
    # n*inv % q = 1 => n*inv = q*m + 1 => n*inv + q*-m = 1
    # => egcd(n, q) = (inv, -m, 1) => inv = egcd(n, q)[0] (mod q)
    return egcd(n, q)[0] % q

def sqrt(n, q):
    # sqrt on PN module: returns two numbers or exception if not exist
    assert n < q
    for i in range(1, q):
        if i * i % q == n:
            return (i, q - i)
        pass
    raise Exception("not found")

class Coord(object):
    def __init__(self,x,y):
        self.x=x
        self.y=y

# System of Elliptic Curve
class EC(object):

    # elliptic curve as: (y**2 = x**3 + a * x + b) mod q
    # - a, b: params of curve formula
    # - p: prime number
    def __init__(self, a, b, p):
        assert 0 < a and a < p and 0 < b and b < p and p > 2
        assert (4 * (a ** 3) + 27 * (b ** 2)) % p != 0
        self.a = a
        self.b = b
        self.p = p
        # just as unique ZERO value representation for "add": (not on curve)
        self.zero = Coord(0, 0)
        pass

    # Judge if the coordinate in the curve
    def is_valid(self, p):
        if p == self.zero:
            return True
        l = (p.y ** 2) % self.p
        r = ((p.x ** 3) + self.a * p.x + self.b) % self.p
        return l == r

    def at(self, x):
        # find points on curve at x
        # - x: int < p
        # - returns: ((x, y), (x,-y)) or not found exception

        assert x < self.p
        ysq = (x ** 3 + self.a * x + self.b) % self.p
        y, my = sqrt(ysq, self.p)
        return Coord(x, y), Coord(x, my)

    def neg(self, p):
        # negate p
        return Coord(p.x, -p.y % self.p)

    # 1.无穷远点 O∞是零元，有O∞+ O∞= O∞，O∞+P=P
    # 2.P(x,y)的负元是 (x,-y mod p)= (x,p-y) ，有P+(-P)= O∞
    # 3.P(x1,y1),Q(x2,y2)的和R(x3,y3) 有如下关系：
    # x3≡k**2-x1-x2(mod p)
    # y3≡k(x1-x3)-y1(mod p)
    # 若P=Q 则 k=(3x2+a)/2y1mod p
    # 若P≠Q，则k=(y2-y1)/(x2-x1) mod p
    def add(self, p1, p2):
        # of elliptic curve: negate of 3rd cross point of (p1,p2) line
        if p1 == self.zero:
            return p2
        if p2 == self.zero:
            return p1
        if p1.x == p2.x and (p1.y != p2.y or p1.y == 0):
            # p1 + -p1 == 0
            return self.zero
        if p1.x == p2.x:
            # p1 + p1: use tangent line of p1 as (p1,p1) line
            k = (3 * p1.x * p1.x + self.a) * inv(2 * p1.y, self.p) % self.p
            pass
        else:
            k = (p2.y - p1.y) * inv(p2.x - p1.x, self.p) % self.p
            pass
        x = (k * k - p1.x - p2.x) % self.p
        y = (k * (p1.x - x) - p1.y) % self.p
        # assert self.is_valid(Coord(x, y))
        return Coord(x, y)

    def min(self,p1,p2):
        p1_ = Coord(p1.x,-p1.y % self.p)
        rs = self.add(p1_,p2)
        rs_ = Coord(rs.x,-rs.y % self.p)
        return rs_

    def mul(self, p, n):
        # n times of elliptic curve
        r = self.zero
        m2 = p
        # O(log2(n)) add
        while 0 < n:
            if n & 1 == 1:
                r = self.add(r, m2)
                pass
            n, m2 = n >> 1, self.add(m2, m2)
            pass
        assert self.is_valid(r)
        return r

    def order(self, g):
        # order of point g
        assert self.is_valid(g) and g != self.zero
        for i in range(1, self.p + 1):
            if self.mul(g, i) == self.zero:
                return i
            pass
        raise Exception("Invalid order")
    pass

class ElGamal(object):
    # ElGamal Encryption
    # pub key encryption as replacing (mulmod, powmod) to (ec.add, ec.mul)
    # - ec: elliptic curve
    # - g: (random) a point on ec

    def __init__(self, ec, g):
        assert ec.is_valid(g)
        self.ec = ec
        self.g = g
        self.n = ec.order(g)
        pass

    def gen(self, priv):
        # generate pub key
        # - priv: priv key as (random) int < ec.q
        # - returns: pub key as points on ec

        return self.ec.mul(g, priv)
       
    def enc(self, plain, pub, r):
        # encrypt
        # - plain: data as a point on ec
        # - pub: pub key as points on ec
        # - r: randam int < ec.q
        # - returns: (cipher1, ciper2) as points on ec
        assert self.ec.is_valid(plain)
        assert self.ec.is_valid(pub)
        return (self.ec.mul(self.g, r), self.ec.add(plain, self.ec.mul(pub, r)))

    def dec(self, cipher, priv, public=0, recv_public=0):
        # decrypt
        # - chiper: (chiper1, chiper2) as points on ec
        # - priv: private key as int < ec.q
        # - returns: plain as a point on ec
        
        #self.check(public, recv_public)
        c1, c2 = cipher
        assert self.ec.is_valid(c1) and ec.is_valid(c2)
        # return self.ec
        dec_pln_x = self.ec.min(c2,self.ec.mul(c1,priv)).x 
        dec_pln_y = self.ec.min(c2,self.ec.mul(c1,priv)).y
        assert self.ec.is_valid(Coord(dec_pln_x,dec_pln_y))
        return Coord(dec_pln_x,dec_pln_y)

if __name__ == "__main__":
    # shared elliptic curve system of examples
    ec = EC(1, 18, 19)
    g, _ = ec.at(7)
    assert ec.order(g) <= ec.p

    # ElGamal enc/dec usage
    eg = ElGamal(ec, g)

    # mapping value to ec point
    # "masking": value k to point ec.mul(g, k)
    # ("imbedding" on proper n:use a point of x as 0 <= n*v <= x < n*(v+1) < q)
    mapping = [ec.mul(g, i) for i in range(eg.n)]
    plain = mapping[7]

    priv = 5
    pub = eg.gen(priv)
    
    cipher = eg.enc(plain, pub, 15)
    decoded = eg.dec(cipher, priv)
    
    assert decoded.x == plain.x and decoded.y == plain.y
    assert cipher != pub
    print("Success!")

