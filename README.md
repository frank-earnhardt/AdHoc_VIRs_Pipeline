VIRs pipeline
Process Vehicle Inspection Reports to infer the state of dimensional tables
We are working with a vehicle fleet inspection agency to populate an analytics dashboard with information about patterns in vehicle inspections amongst their client organizations. Unfortunately, between access controls and resourcing limitations, pulling data directly from a client's vehicle inspection tracking database could take far longer than anyone can afford to wait. However, they already have monthly dumps of vehicle inspection report (VIR) records that contain enough information that we can infer everything we really need to know about both the vehicles being inspected and the client organizations that own those vehicles.

So, we need to process those dumps into a separate data store that allows us to answer questions about who is getting vehicles and inspections and whether they're passing those inspections.

Task
The dumps are named vir_<year><month>.csv which allows them to be processed in order, and your goal is to create any necessary code or scripts necessary to process all dump files in order, updating and adding data until we have a data store that describes the current state of inspections, vehicles that were inspected, and the organizations that own them. Once all data has been processed, write to disk the MVP report we need the data to be able to produce.

The MVP report is a TSV (plus header) named virs_report.tsv that gives statistics on the three organizations with the highest fraction of vehicles that failed their last adjudicated inspection.

It contains three columns:

org_name: The names of the organizations as inferred from the VIR files.
tot_v: How many vehicles with inspections exist in those organizations as aggregated from the three dumps we have.
failed_v: How many vehicles in those organizations are currently in a failed state.
Business logic notes
vehicle_id + inspection_date define a unique inspection report and can be considered a compound primary key.
This is the MVP question we’ll be asking of the data, but that there are expected to be more, so it's better if the data is structured to make that easy.
We do not care about and do not want to retain past states of the data (i.e. we don’t need a time series table)
Vehicles and organizations can change over time, but their IDs will remain the same
Once a vehicle's inspection is conducted, the vehicle is considered inspected and gets an inspection record. However, the inspection can go through an adjudication process which can prevent the inspection record from having a result value in inspection_passed. Also, re-adjudications can change the result of a previously-adjudicated inspection.
The information in the latest inspection report pertaining to a vehicle or an organization is authoritative. For example, if an inspection report indicates that a vehicle belongs to a different organization, we must interpret that as the vehicle having been transferred between organizations.
Until a new inspection result is indicated, the previous inspection result continues to apply. There can be long delays between when an inspection is conducted, and when a result is updated to passing or failing, so each successive dump is likely to update a few inspection records received in previous dumps.
In a given inspection record, only inspection_passed is ever updated, so changes to vehicles or organizations can only be inferred from subsequent inspection records.
You must supply your code as part of your answer. Use whichever data stores and languages with which you're most comfortable, including domain-specific languages such as SQL. The prime focus of this homework is the data logic and structures. The secondary focus is ingestion and export of data from the data store. The setup of the infrastructure is not a focus beyond creating an environment where we can run your code to test it. Please put instructions for setup in a COMMENTS file.

If your code executes from a Unix-like command line and and/or uses a common DBMS/database programs like Postgres or MySql, you can assume we will be able to manage common setup tasks like database installation and initialization, so you don't need to include code to automate setup beyond creating any structures (tables, dataframes, collections) specifically for the data to be processed. Include complete instructions for the installation and setup of any less common software framework and/or data store necessary for the code to run. Managing security and users or anything else besides processing the data is not part of the homework, so please keep setup simple.

Notes
The input files are formatted as double-quote quoted CSVs in which literal double-quotes are doubled (i.e. ""). The delimiter is a pipe (|) character. Each file has its own header.

vehicle_id|inspection_date|vehicle_org_id|org_name|inspection_period_id|inspection_passed
2811|2020-02-06|1920|Economotor|102|TRUE
4021|2020-02-10|1920|Economotor|102|TRUE
Not all columns are needed.

To extract the dumps from vehicle_inspection_reports.tar.gz you can run tar zxvf vehicle_inspection_reports.tar.gz in most any Unix-like command line.

Included files
Here are the files we'll give to you to get you started. Download them when you are ready to begin.

 Download virs_pipeline files (.zip)
Ready to submit?
Don't include anything in your files that could identify you. We assign submissions a random number when they are received so our team does not know whose homework they are evaluating. Multiple team members will review your submission before a decision is made.
