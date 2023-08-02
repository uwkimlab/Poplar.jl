"Systemm for determining BBCH stage and BBCH rows"
@system BBCH begin
    
    # Determine BBCH stage
    BBCH_stage(budburst, leafexpansion, senescent, dormant) => begin
        if dormant
            :BBCH00
        elseif budburst
            :BBCH10
        elseif leafexpansion
            :BBCH11
        elseif senescent
            :BBCH90
        else
            :BBCH30 # shoot development
        end
    end ~ track::Symbol

    # Carbon partitioning table corresponding to BBCH stages.
    BBCH_table => [
      # leaf stem root stor
        0.00 0.00 0.00 0.00 # BBCH00
        0.90 0.05 0.05 0.00 # BBCH11
        0.90 0.05 0.05 0.00 # BBCH19
        0.20 0.50 0.30 0.00 # BBCH30
        0.00 0.67 0.33 0.00 # BBCH90
    ] ~ tabulate(
        rows=(:BBCH00, :BBCH10, :BBCH11, :BBCH30, :BBCH90),
        columns=(:leaf, :stem, :root, :storage),
        parameter
    )
end