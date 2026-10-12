# es_benchmarks() without a set lists the options

    Code
      sets <- es_benchmarks()
    Message
      "cohen_d": d, cuts 0.2, 0.5, and 0.8 (Cohen (1988), d)
      "sawilowsky_d": d, cuts 0.01, 0.2, 0.5, 0.8, 1.2, and 2 (Sawilowsky (2009), d)
      "cohen_r": r, cuts 0.1, 0.3, and 0.5 (Cohen (1988), r)
      "funder_ozer_r": r, cuts 0.05, 0.1, 0.2, 0.3, and 0.4 (Funder & Ozer (2019), r)
      "gignac_szodorai_r": r, cuts 0.1, 0.2, and 0.3 (Gignac & Szodorai (2016), r)
      "cohen_eta2": eta2, cuts 0.01, 0.06, and 0.14 (Cohen (1988), η²)
      "cohen_f": f, cuts 0.1, 0.25, and 0.4 (Cohen (1988), f)
      "chen_or": or, cuts 1.68, 3.47, and 6.71 (Chen et al. (2010), OR at 1% baseline
      risk)

# es_thresholds() validates its input

    Code
      print(x)
    Message
      <es_thresholds> on the "d" scale
      a: |effect| in [0, 0.1)
      b: |effect| in [0.1, 0.3)
      c: |effect| in [0.3, Inf)
      Source: Me

