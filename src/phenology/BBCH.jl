@system BBCH begin
    
    # Determine BBCH stage
    BBCH_stage(budburst, leafexpansion, senescent, dormant) => begin
        if dormant
            :BBCH00
        elseif budburst
            :BBCH11
        elseif leafexpansion
            :BBCH19
        elseif senescent
            :BBCH90
        else
            :BBCH30
        end
    end ~ track::Symbol

    # Carbon partitioning table corresponding to BBCH stages.
    BBCH_table => [
      # leaf stem root
        0.00 0.00 0.00 # BBCH00
        0.90 0.05 0.05 # BBCH11
        0.90 0.05 0.05 # BBCH19
        0.34 0.52 0.14 # BBCH30
        0.34 0.52 0.14 # BBCH90
    ] ~ tabulate(
        rows=(:BBCH00, :BBCH11, :BBCH19, :BBCH30, :BBCH90),
        columns=(:leaf, :stem, :root),
        parameter
    )
end