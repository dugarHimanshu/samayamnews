# Location data

`npm run seed:locations` downloads the official LGD snapshot and loads Telangana + Andhra Pradesh
(state → district → mandal → inhabited village) into `app.locations`.

To improve **Telugu mandal names**, save the client's Telugu mandal list (the district headings
followed by `* mandal` bullets, exactly as it was shared) as `data/client-mandals-te.txt` and re-run
the import. Mandals are matched to LGD by spelling within each district; lines that are notes
(e.g. "…నిర్ధారించాలి") are ignored. Run with `-- --dry-run` to see match counts first; unmatched
mandals are listed in `.cache/lgd/mandals-missing-te.txt`.
