[![Build Status](https://travis-ci.org/sul-dlss/workflow-archiver-job.svg?branch=master)](https://travis-ci.org/sul-dlss/workflow-archiver-job)
[![Coverage Status](https://coveralls.io/repos/github/sul-dlss/workflow-archiver-job/badge.svg?branch=master)](https://coveralls.io/github/sul-dlss/workflow-archiver-job?branch=master)
[![GitHub version](https://badge.fury.io/gh/sul-dlss%2Fworkflow-archiver-job.svg)](https://badge.fury.io/gh/sul-dlss%2Fworkflow-archiver-job)


(Note: as of 2018-06-12, there are no specs.  The spec we have (from 2014) fails even when all the plumbing is provided.)

# Workflow Archiver Job

This project basically provides the `run_archiver` script and configuration in order to perform
workflow archiving.  This moves rows out of the active workflow table to an archive table. The purpose of this is to keep the table of active rows smaller and more performant.

The heavy lifting is done by the `workflow-archiver` gem, so there is no lib directory.

There are no tests, except manual integration testing. All tests are in the `workflow-archiver` gem.
