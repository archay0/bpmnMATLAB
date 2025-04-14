%% ComplexBPMNExample.m
% Example of creating a complex BPMN diagram with advanced features
% This example showcases multiple BPMN element types, pools, lanes, data objects,
% boundary events, and other advanced BPMN constructs

%% Add repository to path
currentDir = pwd;
repoPath = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(repoPath));

%% Create BPMN Generator instance
outputFile = fullfile(repoPath, 'examples', 'output', 'complex_process.bpmn');
bpmn = BPMNGenerator(outputFile);

%% Define a complex hiring process with multiple participants

%% Add Pools and Lanes
% Main process pool
mainPoolId = 'Pool_Company';
bpmn.addPool(mainPoolId, 'Company', 'Process_1', 100, 100, 1000, 600);

% Add lanes for different departments
hrLaneId = 'Lane_HR';
bpmn.addLane(hrLaneId, 'HR Department', '', 100, 100, 1000, 200);

managerLaneId = 'Lane_Manager';
bpmn.addLane(managerLaneId, 'Department Manager', '', 100, 300, 1000, 200);

itLaneId = 'Lane_IT';
bpmn.addLane(itLaneId, 'IT Department', '', 100, 500, 1000, 200);

% Applicant pool
applicantPoolId = 'Pool_Applicant';
bpmn.addPool(applicantPoolId, 'Job Applicant', 'Process_2', 100, 750, 1000, 150);

%% HR Lane Elements
% Start event in HR
startEventId = 'StartEvent_1';
bpmn.addEvent(startEventId, 'Receive Job Application', 'startEvent', 'messageEventDefinition', 150, 150, 36, 36);

% HR tasks
reviewApplicationId = 'Task_ReviewApplication';
bpmn.addSpecificTask(reviewApplicationId, 'Review Application', 'userTask', struct('implementation', 'unspecified'), 250, 150, 100, 80);

checkQualificationsId = 'Task_CheckQualifications';
bpmn.addTask(checkQualificationsId, 'Check Qualifications', 350, 150, 100, 80);

% Gateway after initial review
initialReviewGatewayId = 'Gateway_InitialReview';
bpmn.addGateway(initialReviewGatewayId, 'Qualifications OK?', 'exclusiveGateway', 500, 150, 50, 50);

% Rejection task
rejectApplicationId = 'Task_RejectApplication';
bpmn.addSpecificTask(rejectApplicationId, 'Reject Application', 'serviceTask', struct('implementation', 'unspecified'), 600, 80, 100, 80);

% End event for rejected applications
rejectionEndId = 'EndEvent_Rejected';
bpmn.addEvent(rejectionEndId, 'Application Rejected', 'endEvent', 'terminateEventDefinition', 750, 80, 36, 36);

% Interview scheduling task
scheduleInterviewId = 'Task_ScheduleInterview';
bpmn.addTask(scheduleInterviewId, 'Schedule Interview', 600, 200, 100, 80);

% Boundary event for scheduling issues
scheduleErrorId = 'BoundaryEvent_ScheduleError';
bpmn.addBoundaryEvent(scheduleErrorId, 'Scheduling Conflict', scheduleInterviewId, 'errorEventDefinition', true, 600, 240, 36, 36);

% Error handling task
rescheduleId = 'Task_Reschedule';
bpmn.addTask(rescheduleId, 'Reschedule Interview', 680, 280, 100, 80);

%% Manager Lane Elements
% Interview task
interviewId = 'Task_ConductInterview';
bpmn.addSpecificTask(interviewId, 'Conduct Interview', 'userTask', struct('implementation', 'unspecified'), 250, 350, 100, 80);

% Multiple interviews - loop task
additionalInterviewId = 'Task_AdditionalInterview';
loopProps = struct('multiInstanceLoopCharacteristics', 'sequential');
bpmn.addSpecificTask(additionalInterviewId, 'Additional Interviews', 'userTask', loopProps, 400, 350, 100, 80);

% Decision gateway
hiringDecisionId = 'Gateway_HiringDecision';
bpmn.addGateway(hiringDecisionId, 'Hire Candidate?', 'exclusiveGateway', 550, 350, 50, 50);

% Rejection after interview
rejectAfterInterviewId = 'Task_RejectAfterInterview';
bpmn.addTask(rejectAfterInterviewId, 'Send Rejection', 650, 350, 100, 80);

% Rejection end
rejectionAfterInterviewEndId = 'EndEvent_RejectedAfterInterview';
bpmn.addEvent(rejectionAfterInterviewEndId, 'Rejected After Interview', 'endEvent', '', 800, 350, 36, 36);

% Approved task
approveHiringId = 'Task_ApproveHiring';
bpmn.addTask(approveHiringId, 'Approve Hiring', 650, 450, 100, 80);

%% IT Department Lane Elements
% Prepare equipment task
prepareEquipmentId = 'Task_PrepareEquipment';
bpmn.addTask(prepareEquipmentId, 'Prepare Equipment', 250, 550, 100, 80);

% Setup accounts task
setupAccountsId = 'Task_SetupAccounts';
bpmn.addTask(setupAccountsId, 'Setup IT Accounts', 400, 550, 100, 80);

% Subprocess for onboarding
onboardingSubprocessId = 'SubProcess_Onboarding';
bpmn.addSubProcess(onboardingSubprocessId, 'IT Onboarding Process', 550, 520, 200, 120, true);

% End event - onboarding complete
onboardingCompleteId = 'EndEvent_OnboardingComplete';
bpmn.addEvent(onboardingCompleteId, 'Onboarding Complete', 'endEvent', '', 800, 550, 36, 36);

%% Applicant Pool Elements
% Start event for applicant
applicantStartId = 'StartEvent_Applicant';
bpmn.addEvent(applicantStartId, 'Start Job Search', 'startEvent', '', 150, 800, 36, 36);

% Submit application task
submitApplicationId = 'Task_SubmitApplication';
bpmn.addTask(submitApplicationId, 'Submit Application', 250, 800, 100, 80);

% Wait for response
waitForResponseId = 'Event_WaitForResponse';
bpmn.addEvent(waitForResponseId, 'Wait For Response', 'intermediateCatchEvent', 'messageEventDefinition', 400, 800, 36, 36);

% Receive response gateway
responseGatewayId = 'Gateway_Response';
bpmn.addGateway(responseGatewayId, 'Application Result', 'exclusiveGateway', 500, 800, 50, 50);

% Task for rejected application from applicant side
applicantRejectedId = 'Task_ApplicationRejected';
bpmn.addTask(applicantRejectedId, 'Receive Rejection', 600, 750, 100, 80);

% End event for rejection from applicant side
applicantRejectionEndId = 'EndEvent_ApplicantRejected';
bpmn.addEvent(applicantRejectionEndId, 'Process Ended - Rejected', 'endEvent', '', 750, 750, 36, 36);

% Interview task from applicant perspective
attendInterviewId = 'Task_AttendInterview';
bpmn.addTask(attendInterviewId, 'Attend Interview', 600, 850, 100, 80);

% Final gateway
finalResultGatewayId = 'Gateway_FinalResult';
bpmn.addGateway(finalResultGatewayId, 'Final Result', 'exclusiveGateway', 750, 850, 50, 50);

% Task for hired
hiredTaskId = 'Task_Hired';
bpmn.addTask(hiredTaskId, 'Accept Offer', 850, 800, 100, 80);

% Task for rejected after interview
rejectedAfterInterviewTaskId = 'Task_RejectedAfterInterview';
bpmn.addTask(rejectedAfterInterviewTaskId, 'Process Rejection', 850, 900, 100, 80);

% End events
hiredEndId = 'EndEvent_Hired';
bpmn.addEvent(hiredEndId, 'Process Ended - Hired', 'endEvent', '', 1000, 800, 36, 36);

rejectedEndId = 'EndEvent_RejectedEnd';
bpmn.addEvent(rejectedEndId, 'Process Ended - Rejected', 'endEvent', '', 1000, 900, 36, 36);

%% Add Data Objects and Stores
% Application document
applicationDataId = 'Data_Application';
bpmn.addDataObject(applicationDataId, 'Application Document', false, 200, 220, 36, 50);

% Candidate database
candidateDbId = 'DataStore_CandidateDB';
bpmn.addDataStore(candidateDbId, 'Candidate Database', 1000, 300, 280, 50, 40);

% Interview notes
interviewNotesDataId = 'Data_InterviewNotes';
bpmn.addDataObject(interviewNotesDataId, 'Interview Notes', true, 450, 280, 36, 50);

%% Add Text Annotations
bpmn.addTextAnnotation('Annotation_1', 'Applications should be reviewed within 5 business days', 150, 30, 200, 50);
bpmn.addTextAnnotation('Annotation_2', 'Multiple interviews may be scheduled based on position requirements', 400, 430, 200, 50);

%% Add Sequence Flows in HR Lane
% Start -> Review Application
bpmn.addSequenceFlow('Flow_1', startEventId, reviewApplicationId, [186, 150; 250, 150]);

% Review Application -> Check Qualifications
bpmn.addSequenceFlow('Flow_2', reviewApplicationId, checkQualificationsId, [350, 150; 400, 150]);

% Check Qualifications -> Gateway
bpmn.addSequenceFlow('Flow_3', checkQualificationsId, initialReviewGatewayId, [450, 150; 500, 150]);

% Gateway -> Reject
bpmn.addSequenceFlow('Flow_4', initialReviewGatewayId, rejectApplicationId, [525, 125; 600, 80], '${qualificationsMet == false}');

% Gateway -> Schedule Interview
bpmn.addSequenceFlow('Flow_5', initialReviewGatewayId, scheduleInterviewId, [525, 175; 600, 200], '${qualificationsMet == true}');

% Reject -> End
bpmn.addSequenceFlow('Flow_6', rejectApplicationId, rejectionEndId, [700, 80; 750, 80]);

% Schedule Error -> Reschedule
bpmn.addSequenceFlow('Flow_7', scheduleErrorId, rescheduleId, [618, 258; 680, 280]);

% Reschedule -> Schedule Interview
bpmn.addSequenceFlow('Flow_8', rescheduleId, scheduleInterviewId, [730, 280; 750, 240; 750, 200; 700, 200]);

% Schedule Interview -> Interview
bpmn.addSequenceFlow('Flow_9', scheduleInterviewId, interviewId, [650, 200; 650, 270; 200, 270; 200, 350; 250, 350]);

%% Add Sequence Flows in Manager Lane
% Interview -> Additional Interviews
bpmn.addSequenceFlow('Flow_10', interviewId, additionalInterviewId, [350, 350; 400, 350]);

% Additional Interviews -> Decision Gateway
bpmn.addSequenceFlow('Flow_11', additionalInterviewId, hiringDecisionId, [500, 350; 550, 350]);

% Decision Gateway -> Reject
bpmn.addSequenceFlow('Flow_12', hiringDecisionId, rejectAfterInterviewId, [575, 350; 650, 350], '${hire == false}');

% Decision Gateway -> Approve
bpmn.addSequenceFlow('Flow_13', hiringDecisionId, approveHiringId, [575, 375; 650, 450], '${hire == true}');

% Reject After Interview -> End
bpmn.addSequenceFlow('Flow_14', rejectAfterInterviewId, rejectionAfterInterviewEndId, [750, 350; 800, 350]);

% Approve Hiring -> Prepare Equipment (cross-lane)
bpmn.addSequenceFlow('Flow_15', approveHiringId, prepareEquipmentId, [650, 450; 200, 450; 200, 550; 250, 550]);

%% Add Sequence Flows in IT Lane
% Prepare Equipment -> Setup Accounts
bpmn.addSequenceFlow('Flow_16', prepareEquipmentId, setupAccountsId, [350, 550; 400, 550]);

% Setup Accounts -> Onboarding Subprocess
bpmn.addSequenceFlow('Flow_17', setupAccountsId, onboardingSubprocessId, [500, 550; 550, 550]);

% Onboarding Subprocess -> End
bpmn.addSequenceFlow('Flow_18', onboardingSubprocessId, onboardingCompleteId, [750, 550; 800, 550]);

%% Add Sequence Flows in Applicant Pool
% Start -> Submit Application
bpmn.addSequenceFlow('Flow_19', applicantStartId, submitApplicationId, [186, 800; 250, 800]);

% Submit Application -> Wait For Response
bpmn.addSequenceFlow('Flow_20', submitApplicationId, waitForResponseId, [350, 800; 400, 800]);

% Wait For Response -> Response Gateway
bpmn.addSequenceFlow('Flow_21', waitForResponseId, responseGatewayId, [436, 800; 500, 800]);

% Response Gateway -> Rejected
bpmn.addSequenceFlow('Flow_22', responseGatewayId, applicantRejectedId, [525, 775; 600, 750], '${accepted == false}');

% Response Gateway -> Attend Interview
bpmn.addSequenceFlow('Flow_23', responseGatewayId, attendInterviewId, [525, 825; 600, 850], '${accepted == true}');

% Rejected -> End
bpmn.addSequenceFlow('Flow_24', applicantRejectedId, applicantRejectionEndId, [700, 750; 750, 750]);

% Attend Interview -> Final Result
bpmn.addSequenceFlow('Flow_25', attendInterviewId, finalResultGatewayId, [700, 850; 750, 850]);

% Final Result -> Hired
bpmn.addSequenceFlow('Flow_26', finalResultGatewayId, hiredTaskId, [775, 825; 850, 800], '${hired == true}');

% Final Result -> Rejected After Interview
bpmn.addSequenceFlow('Flow_27', finalResultGatewayId, rejectedAfterInterviewTaskId, [775, 875; 850, 900], '${hired == false}');

% Hired -> End
bpmn.addSequenceFlow('Flow_28', hiredTaskId, hiredEndId, [950, 800; 1000, 800]);

% Rejected After Interview -> End
bpmn.addSequenceFlow('Flow_29', rejectedAfterInterviewTaskId, rejectedEndId, [950, 900; 1000, 900]);

%% Add Message Flows between Pools
% Application submission
bpmn.addMessageFlow('MessageFlow_1', submitApplicationId, startEventId, [300, 780; 300, 700; 168, 700; 168, 168], 'Job Application');

% Interview invitation
bpmn.addMessageFlow('MessageFlow_2', scheduleInterviewId, waitForResponseId, [650, 240; 650, 500; 418, 500; 418, 782], 'Interview Invitation');

% Rejection message
bpmn.addMessageFlow('MessageFlow_3', rejectApplicationId, waitForResponseId, [650, 60; 400, 60; 400, 782], 'Rejection Notice');

% Interview coordination
bpmn.addMessageFlow('MessageFlow_4', interviewId, attendInterviewId, [300, 370; 300, 600; 650, 600; 650, 832], 'Interview Communication');

%% Add Data Associations
% Application data to review task
bpmn.addDataAssociation('DataAssoc_1', applicationDataId, reviewApplicationId, [218, 245; 275, 190]);

% Interview notes
bpmn.addDataAssociation('DataAssoc_2', interviewId, interviewNotesDataId, [350, 350; 450, 305]);

% Database connection
bpmn.addDataAssociation('DataAssoc_3', hiringDecisionId, candidateDbId, [575, 350; 800, 350; 800, 300; 830, 300]);

%% Add Association for Annotation
bpmn.addAssociation('Assoc_1', 'Annotation_1', reviewApplicationId, [250, 55; 300, 110], 'None');
bpmn.addAssociation('Assoc_2', 'Annotation_2', additionalInterviewId, [450, 430; 450, 390], 'None');

%% Save BPMN file
bpmn.saveToBPMNFile();
disp(['Complex BPMN diagram saved to: ', outputFile]);

%% Display successful completion
disp('Complex BPMN example completed successfully!');