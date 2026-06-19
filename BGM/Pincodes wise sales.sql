SELECT 
    sales.analytic_super_category AS super_category,
    sales.pincode AS pincode,
    sales.brand AS brand,
    SUM(sales.gmv) AS total_gmv,
    SUM(sales.units) AS total_units,
    SUM(CASE WHEN sales.is_alpha_seller = TRUE THEN sales.gmv ELSE 0 END) AS alpha_gmv,
    SUM(CASE WHEN sales.is_alpha_seller = TRUE THEN sales.units ELSE 0 END) AS alpha_units
FROM 
    bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
WHERE 
    LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type = 'physical'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND LOWER(sales.marketplace_id) IN ('flipkart')
    AND (sales.order_date_key BETWEEN 20260501 AND 20260531)
    AND sales.analytic_business_unit IN ('BGM')
    AND sales.is_shopsy_order = FALSE
    AND LOWER(sales.brand) IN (
        'muscleblaze', 'little angel', 'luvlap', 'colgate', 'palmolive', 'as-it-is nutrition', 
        'farmley', 'bumtum', 'i-activ', 'lacto calamine', 'tri-activ', 'manna', 'myfitness', 
        'myfitness peanut butter', 'arata', 'baidyanath', 'bblunt', 'beast - x', 'bio-oil', 
        'coco soul', 'hair & care', 'hair and care', 'livon', 'nihar', 'nihar naturals', 
        'parachute', 'parachute advansed', 'parachute advansed men', 'puresense', 'red king', 
        'set wet', 'nakpro', 'wowper', 'yogabar', 'happilo', 'tata', 'tata coffee', 
        'tata coffee grand', 'tata sampann', 'tata sampann organic', 'tata simply better', 
        'tata soulfull', 'tata tea', 'tata tea agni', 'tata tea chakra gold', 
        'tata tea chakra gold gemini', 'tata tea gold', 'tata tea gold care', 'tata tea premium', 
        'tata tea premium care', 'morisons baby dreams', 'nerf', 'the man company', 
        'the woman company', 'naturoz', 'tulsi', 'true elements', 'novel', 'pidilite', 
        'axe', 'axe signature', 'brut', 'rexona', 'tedibar', 'casio', 'flair', 'flair creative', 
        'himalaya', 'himalaya herbals', 'hershey''s', 'fogg scent', 'beardo', 'boroplus', 
        'creme 21', 'dermi cool', 'dermicool', 'emami', 'fair and handsome', 'kesh king', 
        'kesh king organics', 'kozicare', 'layer''rmargo', 'medimix', 'navkar', 'navratna', 
        'navratna therapy', 'neko', 'zandu', 'biotique', 'biotique advanced organics', 'gnc', 
        'motul', 'scorist', 'pintola', 'wild stone', 'wild stone code', 'wonderland', 
        'wonderland foods', 'aveeno baby', 'buds & berries', 'calvin klein', 'chik', 'indica', 
        'karthika', 'meera', 'nyle', 'raaga professional', 'spinz', 'spoo', 'oscar', 
        'bombay shaving company', 'lotus', 'lotus botanicals', 'lotus herbals', 
        'lotus herbals professional', 'lotus make - up', 'lotus organic', 'lotus organics+', 
        'lotus professional', 'manforce', 'manforce epic', 'skinn by titan', 'nutrabay', 
        'just herbs', 'minara', 'blue heaven', 'cipla', 'endura', 'endura mass', '1st step', 
        'bigmuscles nutrition', 'bolas', 'doctor''s choice', 'continental coffee', 'gemini'
    )
GROUP BY 
    sales.analytic_super_category,
    sales.pincode,
    sales.brand;