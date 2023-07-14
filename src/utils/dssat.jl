function curve(type, xb, x1, x2, xm, x)
    # Default y value
    y = 1.0

    # Return default
    if lowercase(type) == "non"
        return y
    end

    # Linear
    if lowercase(type) == "lin"
        y = 0.0
        if x > xb && x < x1
            y = (x - xb) / (x1 - xb)
        end
        if x >= x1 && x <= x2
            y = 1.0
        end
        if x > x2 && x < xm
            y = 1.0 - (x - x2) / (xm - x2)
        end
        y = max(y, 0.0)
        y = min(y, 1.0)
    end

    # Quadratic
    if lowercase(type) == "qdr"
        y = 0.0
        if x > xb && x < x1
            y = 1.0 - ((x1 - x) / (x1 - xb)) ^ 2
        end
        if x >= x1 && x <= x2
            y = 1.0
        end
        if x > x2 && x < xm
            y = 1.0 - ((x - x2) / (xm - x2)) ^ 2
        end
        y = max(y, 0.0)
        y = min(y, 1.0)
    end

    # Inverse linear
    if lowercase(type) == "inl"
        y = 1.0
        if x > x1 && x < x2
            y = 1.0 - (1.0 - xm) * ((x - x1) / (x2 - x1))
        end
        if x >= x2
            y = xm
        end
        y = max(y, xm)
        y = min(y, 1.0)
    end

    # Short day
    if lowercase(type) == "sho"
        if x <= x1
            y = 1.0
        elseif x > x1 && x < x2
            y = 1.0 - (1.0 - xm) * ((x - x1) / (x2 - x1))
        elseif x >= x2
            y = xm
        end
        y = max(y, xm)
        y = min(y, 1.0)
    end

    # Long day
    if lowercase(type) == "lon"
        if x < x2
            y = xm
        elseif x >= x2 && x < x1
            y = 1.0 - (1.0 - xm) * ((x1 - x) / (x1 - x2))
        else
            y = 1.0
        end
        y = max(y, xm)
        y = min(y, 1.0)
    end

    # Sine
    if lowercase(type) == "sin"
        y = 0.0
        if x > xb && x < x1
            y = 0.5 * (1.0 + cos(2.0 * pi * (x - x1) / (2.0 * (x1 - xb))))
        end
        if x >= x1 && x <= x2
            y = 1.0
        end
        if x > x2 && x < xm
            y = 0.5 * (1.0 + cos(2.0 * pi * (x2 - x) / (2.0 * (xm - x2))))
        end
        y = max(y, 0.0)
        y = min(y, 1.0)
    end

    # Reversible
    if lowercase(type) == "rev"
        y = 1.0
        if x > xb && x < x1
            y = 1.0 - (x - xb) / (x1 - xb)
        end
        if x >= x1 && x <= x2
            y = 0.0 - (x - x1) / (x2 - x1)
        end
        if x > x2
            y = -1.0
        end
        y = max(y, -1.0)
        y = min(y, 1.0)
        y *= xm
    end

    # Dehardening
    if lowercase(type) == "dhd"
        y = 0.0
        if x > xb && x < x1
            y = (x - xb) / (x1 - xb)
        end
        if x >= x1 && x <= x2
            y = 1.0
        end
        if x > x2
            y = 1.0
        end
        y = max(y, 0.0)
        y = min(y, 1.0)
        y *= xm
    end

    if lowercase(type) == "drd"
        y = x2
        if x > xb && x < x1
            y = x2 + (xm - x2) * (x - xb) / (x1 - xb)
        end
        if x >= x1
            y = xm
        end
        y = max(y, x2)
        y = min(y, xm)
    end

    if lowercase(type) == "cdd"
        y = x2
        if x > xb && x < x1
            y = xm - (xm - x2) * ((x1 - x) / (x1 - xb)) ^ 2
        end
        if x >= x1
            y = xm
        end
        y = max(y, x2)
        y = min(y, xm)
    end

    if lowercase(type) == "exk"
        y = xb - exp(x1 * (x - x2) / xm)
    end

    if lowercase(type) == "vop"
        y = 0.0
        if x > xb && x < xm
            y = ((x - xb) ^ x2) * (xm - x) / ((x1 - xb) ^ x2) / (xm - x1)
        end
        if x >= xm
            y = 0.0
        end
        y = max(y, 0.0)
    end

    if lowercase(type) == "q10"
        y = x1 * x2 ^ ((x - xb) / 10.0)
    end

    if lowercase(type) == "pwr"
        if x < 0.0
            y = x2 * xb * 0.0 ^ x1
        else
            y = x2 * xb * x ^ x1
        end
    end

    return y
end