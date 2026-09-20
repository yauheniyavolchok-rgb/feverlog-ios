steps:
1. MVP to use when my cub is sick
  a. structure and plan, deal with fever of my cub and survive
  b. GitHub Repo and plan, ASD, SDR, logs and notes
  c. design and logos, cute parts
  d. components and feature plan and critics
2. Medication Safety Engine (hardcoded thresholds so far, later RAG? mb). 
3. Add design and features, test sharing and sync,
     - anon user and uuid from sup abase - to avoid registration routine first, but in case of sharing later will require authorisation and then sharing household with other user(s)
     - > kids belong to household level \
       > data and temperature logs storer at Supabase with RLS on uuid anan=true anyway
       > auth with Apple ID or any other later - inherit data and avoid migration from device to cloud later
       > conflict resolution is not a problem before the intention to share is filtered by authentication process
       > conflict and merge anyway with Last Enter Wins 
5. Add languages (UA, mb Ru)
6. Add scraper or compendium info (update possibilities? guidance per country or WHO?)
7. Add protocol info (WHO or country? scrape or API? or manual update and versioning?) 
8. Share to Dr.Baby clinic download link and QR
9. Add function share with your doctor at Dr.Baby 
10. celebrate ;) 

<img width="347" height="743" alt="image" src="https://github.com/user-attachments/assets/9da52b32-0095-428d-baa2-85a38854e183" />
