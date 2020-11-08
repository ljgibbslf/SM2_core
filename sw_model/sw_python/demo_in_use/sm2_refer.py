#!/usr/bin/env python3

#sm2 reference python code
#SM2 硬件实现的 Python 参考代码
#original ECC author : 
#                       @github
#edited SM2 author ：
#                       lf_gibbs@163.com  OpenIC SIG 
#基于 github 上开源的 ECC 源代码修改整理得到



import collections
import hashlib
import random

#椭圆曲线
EllipticCurve = collections.namedtuple('EllipticCurve', 'name p a b g n h')

#secp256k1曲线
secp256k1_curve = EllipticCurve(
    'secp256k1',
    # Field characteristic.
    p=0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f,
    # Curve coefficients.
    a=0,
    b=7,
    # Base point.
    g=(0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798,
       0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8),
    # Subgroup order.
    n=0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141,
    # Subgroup cofactor.
    h=1,
)

#SM2 标准中示例曲线
sm2_curve = EllipticCurve(
    'sm2',
    # Field characteristic.
    p=0xFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFF,
    # Curve coefficients.
    a=0xFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFF-3,
    b= 0x28E9FA9E9D9F5E344D5A9E4BCF6509A7F39789F515AB8F92DDBCBD414D940E93,

    # Base point.
    g = (0x421DEBD6_1B62EAB6_746434EB_C3CC315E_32220B3B_ADD50BDC_4C4E6C14_7FEDD43D,
        0x0680512B_CBB42C07_D47349D2_153B70C4_E5D7FDFC_BFA36EA1_A85841B9_E46E09A2),
    
    # Subgroup order.
    n=0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141,
    # Subgroup cofactor.
    h=1,
)

#SM2 常用曲线 p256
sm2_curve_p256 = EllipticCurve(
    'sm2_p256',
    # Field characteristic.
    p=0xFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFF,
    # Curve coefficients.
    a=0xFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFC,
    b= 0x28E9FA9E_9D9F5E34_4D5A9E4B_CF6509A7_F39789F5_15AB8F92_DDBCBD41_4D940E93,

    # Base point.
    g = (0x32C4AE2C_1F198119_5F990446_6A39C994_8FE30BBF_F2660BE1_715A4589_334C74C7,
        0xBC3736A2_F4F6779C_59BDCEE3_6B692153_D0A9877C_C62A4740_02DF32E5_2139F0A0),
    
    # Subgroup order.
    n=0xFFFFFFFE_FFFFFFFF_FFFFFFFF_FFFFFFFF_7203DF6B_21C6052B_53BBF409_39D54123,
    # Subgroup cofactor.
    h=1,
)

# 模运算函数，除模逆运算外均使用内置运算符 ##########################################################

def inverse_mod(k, p):
    """
    模逆模块返回 x , (x * k) % p == 1
    k 非零，p 为素数
    Returns the inverse of k modulo p.
    This function returns the only integer x such that (x * k) % p == 1.
    k must be non-zero and p must be a prime.
    """
    if k == 0:
        raise ZeroDivisionError('division by zero')

    if k < 0:
        # k ** -1 = p - (-k) ** -1  (mod p)
        return p - inverse_mod(-k, p)

    # Extended Euclidean algorithm.
    s, old_s = 0, 1
    t, old_t = 1, 0
    r, old_r = p, k

    while r != 0:
        quotient = old_r // r
        old_r, r = r, old_r - quotient * r
        old_s, s = s, old_s - quotient * s
        old_t, t = t, old_t - quotient * t

    gcd, x, y = old_r, old_s, old_t

    assert gcd == 1 #测试 k 与 p 互素
    assert (k * x) % p == 1 #测试互逆

    return x % p


# 椭圆曲线点运算函数 #########################################
def is_on_curve(point):
    """检测该点是否位于曲线上
    Returns True if the given point lies on the elliptic curve."""
    if point is None:
        # None represents the point at infinity.
        return True

    x, y = point
    on_curve = (y * y - x * x * x - curve.a * x - curve.b) % curve.p == 0
    return on_curve


def point_neg(point):
    """返回该点关于x轴的对称点
    Returns -point."""
    assert is_on_curve(point)

    if point is None:
        # -0 = 0
        return None

    x, y = point
    result = (x, -y % curve.p)

    assert is_on_curve(result)

    return result

def cood_trans(jacob_point):
    '''将雅各比坐标转换成仿射坐标'''

    if jacob_point is None:
        return None

    x,y,z = jacob_point
    z2 = z ** 2 % curve.p
    z3 = z2 * z % curve.p
    # print('Debug: z2=%x\n'%z2)
    # print('Debug: z3=%x\n'%z3)

    result_x = x * inverse_mod(z2, curve.p) % curve.p # x/(z^2)
    result_y = y * inverse_mod(z3, curve.p) % curve.p # y/(z^3)

    result = (result_x,result_y)
    assert is_on_curve(result)

    return result

def point_add(point1, point2):
    """放射坐标系下点加/倍点运算"""

    if point1 is None:
        # 0 + point2 = point2
        return point2
    if point2 is None:
        # point1 + 0 = point1
        return point1
    
    assert is_on_curve(point1)
    assert is_on_curve(point2)

    x1, y1 = point1
    x2, y2 = point2

    if x1 == x2 and y1 != y2: 
        # point1 + (-point1) = 0 两点关于x轴对称
        return None

    if x1 == x2:
        # point1 == point2 倍点运算
        m = (3 * x1 * x1 + curve.a) * inverse_mod(2 * y1, curve.p)
    else:
        # point1 != point2 点加运算
        m = (y1 - y2) * inverse_mod(x1 - x2, curve.p)

    x3 = m * m - x1 - x2
    y3 = y1 + m * (x3 - x1)
    result = (x3 % curve.p,
              -y3 % curve.p)

    assert is_on_curve(result)

    return result

def point_double_jacob(point1):
    """雅各比坐标系下的倍点运算"""

    if point1 is None:
        return point1

    t0,t1,t2,t3 = (0,0,0,0)
    
    x0, y0 ,z0= point1
    #z0 = 1

    zr = (2*y0*z0) % curve.p

    xr = ((3*x0*x0 + curve.a * z0*z0*z0*z0) * (3*x0*x0 + curve.a * z0*z0*z0*z0) - 8 * x0 * y0 *y0) % curve.p
    yr = ((3*x0*x0 + curve.a * z0*z0*z0*z0) * (4*x0*y0*y0 - xr) - 8*y0*y0*y0*y0) % curve.p
    t1 = (zr * zr) % curve.p
    t2 = (zr * zr * zr) % curve.p
    # xr = xr * inverse_mod(t1, curve.p)% curve.p
    # yr = yr * inverse_mod(t2, curve.p)% curve.p

    #step

    t1 = z0*z0 % curve.p#z0^2

    x1 = (x0 - t1) % curve.p#x0 -  z0*z0
    y1 = (x0 + t1) % curve.p#x0 +  z0*z0
    print('x1=%x\n'%x1)
    print('y1=%x\n'%y1)

    y1 = (y1 * x1) % curve.p#(x0 - z0*z0)(x0 + z0*z0)
    t0 = (y0 * y0) % curve.p#y0 * y0
    z1 = (y0 * z0) % curve.p#y0z0
    print('y1=%x\n'%y1)
    print('t0=%x\n'%t0)
    print('z1=%x\n'%z1)

    t0 = (t0 + t0) % curve.p#2y0^2
    t2 = (y1 + y1) % curve.p#2(x0 - z0*z0)(x0 + z0*z0)
    print('t0=%x\n'%t0)
    print('t2=%x\n'%t2)

    z1 = (z1 + z1) % curve.p#z=2y0z0
    y1 = (y1 + t2) % curve.p#3(x0 - z0*z0)(x0 + z0*z0)
    print('z1=%x\n'%z1)
    print('y1=%x\n'%y1)

    t2 = (y1 * y1) % curve.p#(3(x0 - z0*z0)(x0 + z0*z0))^2
    t1 = (t0 * t0) % curve.p#4y0^4
    t0 = (t0 * x0) % curve.p#2y0^2 ·x0
    print('t2=%x\n'%t2)
    print('t1=%x\n'%t1)
    print('t0=%x\n'%t0)

    t0 = (t0 + t0) % curve.p#4y0^2 ·x0
    print('t0=%x\n'%t0)
    x1 = (t0 + t0) % curve.p#8y0^2 ·x0
    print('x1=%x\n'%x1)
    x1 = (t2 - x1) % curve.p#(3(x0 - z0*z0)(x0 + z0*z0))^2 - 8y0^2 ·x0
    print('x1=%x\n'%x1)

    t1 = (t1 + t1) % curve.p#8y0^4
    t0 = (t0 - x1) % curve.p#4y0^2 ·x0 - (3(x0 - z0*z0)(x0 + z0*z0))^2 - 8y0^2 ·x0
    print('t1=%x\n'%t1)
    print('t0=%x\n'%t0)

    y1 = (y1 * t0) % curve.p#(3(x0 - z0*z0)(x0 + z0*z0))(4y0^2 ·x0 - x1)
    print('y1=%x\n'%y1)
    y1 = (y1 - t1) % curve.p# (3(x0 - z0*z0)(x0 + z0*z0))(4y0^2 ·x0 - x1) - 8y0^4
    print('y1=%x\n'%y1)

    t1 = z1*z1 % curve.p
    print('t1=%x\n'%t1)
    t2 = t1*z1 % curve.p
    print('t2=%x\n'%t2)

    return (x1,y1,z1)

def point_add_jacob(point1_jacob,point2):
    ''' 雅各比-仿射混合坐标 点加运算
        point1_jacob 雅各比坐标
        point2 仿射坐标
    ''' 
    if point1_jacob is None:
        # 0 + point2 = point2
        return (point2[0],point2[1],1) #转换为jacob坐标

    if point2 is None:
        # point1_jacob + 0 = point1_jacob
        return point1_jacob

    #输入坐标点
    (x0,y0,z0) = point1_jacob
    (x1,y1) = point2

    #输出结果
    (x2,y2,z2) = (0,0,0)

    #临时变量
    (t0,t1,t2) = (0,0,0)

    #refer
    Ar = ( x1 * (z0**2) - x0 ) % curve.p
    Br = ( y1 * (z0**3) - y0 ) % curve.p
    xr = ( Br**2 - Ar**3 - 2*x0*Ar**2 ) % curve.p
    yr = ( Br*(x0 * Ar**2 - xr) - y0*Ar**3 ) % curve.p
    zr = ( Ar * z0 ) % curve.p

    #(x2,y2,z2) = (xr,yr,zr)

    t2 = z0 * z0 % curve.p # z0^2
    t0 = z0 * y1 % curve.p # z0y1
    print('t2=%x\n'%t2)
    print('t0=%x\n'%t0)

    t1 = t2 * t0 % curve.p # z0^3 y1
    z2 = x1 * t2 % curve.p # x1z0^2
    print('t1=%x\n'%t1)
    print('z2=%x\n'%z2)

    t0 = (z2 - x0) % curve.p # X1Z0^2 – X0
    t1 = (t1 - y0) % curve.p # z0^3 *y1 - y0
    print('t0=%x\n'%t0)
    print('t1=%x\n'%t1)

    z2 = t0 * z0 % curve.p # Az0
    t2 = t0 * t0 % curve.p # A^2
    print('z2=%x\n'%z2)
    print('t2=%x\n'%t2)

    y2 = t0 * t2 % curve.p # A^3
    t2 = t2 * x0 % curve.p # x0A^2
    x2 = t1 * t1 % curve.p # B^2
    print('y2=%x\n'%y2)
    print('t2=%x\n'%t2)
    print('x2=%x\n'%x2)

    x2 = (x2 - y2) % curve.p # B^2 - A^3
    t0 = t2 + t2 % curve.p # 2x0A^2
    print('x2=%x\n'%x2)
    print('t0=%x\n'%t0)

    x2 = (x2 - t0) % curve.p # B^2 - A^3 - 2x0A^2
    print('x2=%x\n'%x2)
 
    t2 = (t2 - x2) % curve.p # x0A^2 - x2
    print('t2=%x\n'%t2)

    t1 = t1 * t2 % curve.p # B (x0A^2 - x2)
    y2 = y0 * y2 % curve.p # y0A^3
    t2 = z2 * z2 % curve.p # z2^2 
    print('t1=%x\n'%t1)
    print('t2=%x\n'%t2)
    print('y2=%x\n'%y2)

    y2 = (t1 - y2) % curve.p # B (x0A^2 - x2) - y0A^3
    print('y2=%x\n'%y2)

    return (x2,y2,z2)

def scalar_mult(k, point,jacob = 0):
    """调用点加与倍点进行点乘运算"""
    assert is_on_curve(point)

    if k % curve.n == 0 or point is None:
        return None

    if k < 0:
        # k * point = -k * (-point)
        return scalar_mult(-k, point_neg(point),jacob)

    result = None
    addend = point

    if jacob:
        mask = 0x80000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000
        while mask:
            # Double.
            result = point_double_jacob(result)

            if k & mask:
                # Add.
                result = point_add_jacob(result, curve.g)
        
            mask >>= 1
    else:   
        while k:
            if k & 1:
                # Add.
                result = point_add(result, addend)

            # Double.
            addend = point_add(addend, addend)

            k >>= 1

    #如使用Jacob坐标系，则进行坐标转换
    if jacob:
        result = cood_trans(result)

    #验证结果在曲线上，若不在则结果错误
    assert is_on_curve(result)
    
    return result


#Python 主函数
#Demo SM2_MP 运行SM2标准示例曲线·点乘
#Demo SM2_MP_JACOB 运行SM2标准示例曲线·点乘(JACOB坐标方法)
#Demo SM2_MP_COM 比较两种坐标计算方法
#Demo SM2_INT_TEST 内部测试

if __name__ == "__main__":
    #选择 Demo
    # demo = 'SM2_MP'
    demo = 'SM2_MP_JACOB'
    # demo = 'SM2_MP_COM'
    # demo = 'SM2_INT_TEST'
    print('Select demo {}'.format(demo))

    #选择曲线
    curve = sm2_curve_p256
    print('Select curve {}'.format(curve.name))

    #检查曲线参数：基点是否位于曲线上
    is_on_curve(curve.g)
    print('Pass: G is on the curve.')


    if demo == 'SM2_MP':
        #k = 0x4C62EEFD_6ECFC2B9_5B92FD6C_3D957514_8AFA1742_5546D490_18E5388D_49DD7B4F
        k = 0x59276E27_D506861A_16680F3A_D9C02DCC_EF3CC1FA_3CDBE4CE_6D54B80D_EAC1BC21
        result = scalar_mult(k,curve.g)
        print('Run demo {}'.format(demo))
        print('Result:(%X,%x)'%(result[0],result[1]))
        if (result[0] == 0x04EBFC71_8E8D1798_62043226_8E77FEB6_415E2EDE_0E073C0F_4F640ECD_2E149A73 \
            and result[1] == 0xE858F9D8_1E5430A5_7B36DAAB_8F950A3C_64E6EE6A_63094D99_283AFF76_7E124DF0):
            print('Result Pass!')
        else:
            print('Result Fail!')


    elif demo == 'SM2_MP_JACOB':
        k = 0x59276E27_D506861A_16680F3A_D9C02DCC_EF3CC1FA_3CDBE4CE_6D54B80D_EAC1BC21
        result = scalar_mult(k,curve.g,jacob=1)
        print('Run demo {}'.format(demo))
        print('Result:(%X,%x)'%(result[0],result[1]))
        if (result[0] == 0x04EBFC71_8E8D1798_62043226_8E77FEB6_415E2EDE_0E073C0F_4F640ECD_2E149A73 \
            and result[1] == 0xE858F9D8_1E5430A5_7B36DAAB_8F950A3C_64E6EE6A_63094D99_283AFF76_7E124DF0):
            print('Result Pass!')
        else:
            print('Result Fail!')


    elif demo == 'SM2_MP_COM':
        k = 87
        result = scalar_mult(k,curve.g,jacob=0)
        result_j = scalar_mult(k,curve.g,jacob=1)
        print('Run demo {}'.format(demo))
        print('Result:(%X,%x)'%(result[0],result[1]))
        print('Result_Jacob:(%X,%x)'%(result_j[0],result_j[1]))
        if (result[0] == result_j[0] \
            and result[1] == result_j[1]):
            print('Test Pass!')
        else:
            print('Test Fail!')


    elif demo == 'SM2_INT_TEST':
        k = 2
        result = scalar_mult(k,curve.g,jacob=0)
        
        result_j = None
        result_j = point_add_jacob(result_j,curve.g)#P
        result_j = point_double_jacob(result_j)#2P
        # result_j = point_double_jacob((curve.g[0],curve.g[1],1))#
        # result_j = point_add_jacob(result_j,curve.g)#7P
        result_j = cood_trans(result_j)

        print('Run demo {}'.format(demo))
        print('Result:(%X,%x)'%(result[0],result[1]))
        print('Result_Jacob:(%X,%x)'%(result_j[0],result_j[1]))
        if (result[0] == result_j[0] \
            and result[1] == result_j[1]):
            print('Test Pass!')
        else:
            print('Test Fail!')

    pass



