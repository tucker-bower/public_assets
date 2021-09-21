version 1.0 

workflow get_fits {
  input {
    String library_id
    String run_id
    File clinical_rscript
    File generate_uri_rb
    File aetiologies_csv
    File sigs_filter_py
  }
  call generate_uri { input: library_id = library_id, run_id = run_id, generate_uri_rb = generate_uri_rb }
  call fit_sigs { input: vcf = generate_uri.uri, clinical_rscript = clinical_rscript, library_id = library_id }
  call filter_sigs {input: sigs_filter_py = sigs_filter_py, aetiologies_csv = aetiologies_csv, signatures_csv = fit_sigs.signatures_csv }
#  call cleanup_vcf_copy { input: library_id = library_id, run_id = run_id, filtered_csv = filter_sigs.filtered_csv }

  output {
    File uri = generate_uri.uri
    File signatures_csv = fit_sigs.signatures_csv
    File filtered_csv = filter_sigs.filtered_csv
  }
}

task generate_uri {
  input {
    String library_id
    String run_id
    File generate_uri_rb
  }
  command {
    ruby ${generate_uri_rb} --run=${run_id} --library=${library_id}
  }
  output {
    File uri = read_string("uri.txt")
  }
  runtime {
    docker: "tuckerbower/mutationalpatterns:latest"
  }
}

task fit_sigs {
  input {
    File vcf
    File clinical_rscript
    String library_id
  }
  command {
    Rscript ${clinical_rscript} ${vcf} ${library_id}
  }
  output {
    File signatures_csv = "sbs_signatures.csv"
  }
  runtime {
    docker: "tuckerbower/mutationalpatterns:latest"
    memory: "8 GB"
  }
}
task filter_sigs {
  input {
    File aetiologies_csv
    File signatures_csv
    File sigs_filter_py
  }
  command {
    python3.8 ${sigs_filter_py} -f ${signatures_csv} -a ${aetiologies_csv}
  }
  output {
    File filtered_csv = "sbs_signatures_filtered.csv"
  }
  runtime {
    docker: "tuckerbower/mutationalpatterns:latest"
  }
}

# task cleanup_vcf_copy {
#   input {
#     String run_id
#     String library_id
#     File filtered_csv
#   }

#   # cat the filtered_csv here, solely to force this step to wait until the rest of the steps are completed
#   command {
#     cat ${filtered_csv}; 
##    gsutil rm gs://prov-mgl-tso500-mutsigs/wdl_output/${run_id}/${library_id}/output/${library_id}.filtered.genome.vcf
## For some reason, this was removing the entire output folder
#   }
#   runtime {
#     docker: "gcr.io/google.com/cloudsdktool/cloud-sdk:latest"
#   }
# }
