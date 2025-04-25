%% Complexbpmnexample.m
% Example of Creating A Complex BPMN Diagram with Advanced Features
% This example showcases multiple bpmn element types, pools, lanes, data objects,
% Boundary Events, and other Advanced BPMN Constructs
n%% Add Repository to Path
nrepoPath = fileparts(fileparts(mfilename('fullpath')));
nn%% Create bpmn generator instance
outputFile = fullfile(repoPath, 'examples', 'output', 'Complex_process.bpmn');
nn%% Define a Complex Hiring Process with Multiple participants
n%% Add pools and lanes
% Main Process Pool
mainPoolId = 'Pool_company';
bpmn.addPool(mainPoolId, 'Company', 'Process_1', 100, 100, 1000, 600);
n% Add lanes for different departments
hrLaneId = 'Lane_hr';
bpmn.addLane(hrLaneId, 'HR Department', '', 100, 100, 1000, 200);
nmanagerLaneId = 'Lane_manager';
bpmn.addLane(managerLaneId, 'Department Manager', '', 100, 300, 1000, 200);
nitLaneId = 'Lane_it';
bpmn.addLane(itLaneId, 'IT Department', '', 100, 500, 1000, 200);
n% Applicant pool
applicantPoolId = 'Pool_applicant';
bpmn.addPool(applicantPoolId, 'Job Applicant', 'Process_2', 100, 750, 1000, 150);
n%% HR Lane Elements
% Start event in HR
startEventId = 'Start event_1';
bpmn.addEvent(startEventId, 'Receive Job Application', 'start event', 'Message event definition', 150, 150, 36, 36);
n% HR tasks
reviewApplicationId = 'Task_reviewapplication';
bpmn.addSpecificTask(reviewApplicationId, 'Review Application', 'userTask', struct('implementation', 'unspecified'), 250, 150, 100, 80);
ncheckQualificationsId = 'Task_Checkqualifications';
bpmn.addTask(checkQualificationsId, 'Check qualifications', 350, 150, 100, 80);
n% Gateway after initial review
initialReviewGatewayId = 'Gateway_initialreview';
bpmn.addGateway(initialReviewGatewayId, 'Qualifications OK?', 'exclusiveGateway', 500, 150, 50, 50);
n% Rejection Task
rejectApplicationId = 'Task_REJectopplication';
bpmn.addSpecificTask(rejectApplicationId, 'Reject application', 'service act', struct('implementation', 'unspecified'), 600, 80, 100, 80);
n% End event for rejected applications
rejectionEndId = 'Endvent_rejected';
bpmn.addEvent(rejectionEndId, 'Application Rejected', 'end event', 'Termate Event definition', 750, 80, 36, 36);
n% Interview Scheduling Task
scheduleInterviewId = 'Task_scheduleinterview';
bpmn.addTask(scheduleInterviewId, 'Schedule interview', 600, 200, 100, 80);
n% Boundary Event for Scheduling Issues
scheduleErrorId = 'boundaryEvent_scheduleerror';
bpmn.addBoundaryEvent(scheduleErrorId, 'Scheduling Conflict', scheduleInterviewId, 'errore definition', true, 600, 240, 36, 36);
n% Error handling task
rescheduleId = 'Task_Reschedule';
bpmn.addTask(rescheduleId, 'Reschedule interview', 680, 280, 100, 80);
n%% Manager Lane Elements
% Interview Task
interviewId = 'Task_conduct interview';
bpmn.addSpecificTask(interviewId, 'Conduct interview', 'userTask', struct('implementation', 'unspecified'), 250, 350, 100, 80);
n% Multiple interviews - Loop Task
additionalInterviewId = 'Task_additional interview';
loopProps = struct('Multi -instilloopecharacteristics', 'sequential');
bpmn.addSpecificTask(additionalInterviewId, 'Additional interviews', 'userTask', loopProps, 400, 350, 100, 80);
n% Decision gateway
hiringDecisionId = 'Gateway_hiringdecision';
bpmn.addGateway(hiringDecisionId, 'Hire Candidate?', 'exclusiveGateway', 550, 350, 50, 50);
n% Rejection after interview
rejectAfterInterviewId = 'Tasks';
bpmn.addTask(rejectAfterInterviewId, 'Send rejection', 650, 350, 100, 80);
n% Rejection end
rejectionAfterInterviewEndId = 'Endvent_RETAFTER interview';
bpmn.addEvent(rejectionAfterInterviewEndId, 'Rejected after interview', 'end event', '', 800, 350, 36, 36);
n% Approved Task
approveHiringId = 'Task_approvehiring';
bpmn.addTask(approveHiringId, 'APPROVE HIRING', 650, 450, 100, 80);
n%% It Department Lane Elements
% Prepare Equipment Task
prepareEquipmentId = 'Task_PrareParese equipment';
bpmn.addTask(prepareEquipmentId, 'Prepare equipment', 250, 550, 100, 80);
n% Setup Accounts Task
setupAccountsId = 'Task_setupAccounts';
bpmn.addTask(setupAccountsId, 'Setup IT Accounts', 400, 550, 100, 80);
n% subProcess for onboarding
onboardingSubprocessId = 'subProcess onboarding';
bpmn.addSubProcess(onboardingSubprocessId, 'IT onboarding Process', 550, 520, 200, 120, true);
n% End Event - Onboarding Complete
onboardingCompleteId = 'Endvent_onboardingComplete';
bpmn.addEvent(onboardingCompleteId, 'Onboarding complete', 'end event', '', 800, 550, 36, 36);
n%% Applicant Pool Elements
% Start Event for Applicant
applicantStartId = 'Start event_Applicant';
bpmn.addEvent(applicantStartId, 'Start job search', 'start event', '', 150, 800, 36, 36);
n% Submit Application Task
submitApplicationId = 'Task_submitaplication';
bpmn.addTask(submitApplicationId, 'Submit application', 250, 800, 100, 80);
n% Wait for Response
waitForResponseId = 'Event Wait for Response';
bpmn.addEvent(waitForResponseId, 'Wait for Response', 'Intermediatecatch event', 'Message event definition', 400, 800, 36, 36);
n% Receive Response Gateway
responseGatewayId = 'Gateway_Response';
bpmn.addGateway(responseGatewayId, 'Application Result', 'exclusiveGateway', 500, 800, 50, 50);
n% Task for Rejected Application from Applicant Side
applicantRejectedId = 'Task Application Rejected';
bpmn.addTask(applicantRejectedId, 'Receive rejection', 600, 750, 100, 80);
n% End event for rejection from Applicant Side
applicantRejectionEndId = 'Endvent_Applicantrejected';
bpmn.addEvent(applicantRejectionEndId, 'Process Ended - Rejected', 'end event', '', 750, 750, 36, 36);
n% Interview Task From Applicant Perspective
attendInterviewId = 'Task_attendinterView';
bpmn.addTask(attendInterviewId, 'Attend interview', 600, 850, 100, 80);
n% Final Gateway
finalResultGatewayId = 'Gateway_finalresult';
bpmn.addGateway(finalResultGatewayId, 'Final result', 'exclusiveGateway', 750, 850, 50, 50);
n% Task for Hired
hiredTaskId = 'Task_hired';
bpmn.addTask(hiredTaskId, 'Accept offer', 850, 800, 100, 80);
n% Task for rejected after interview
rejectedAfterInterviewTaskId = 'Tasks';
bpmn.addTask(rejectedAfterInterviewTaskId, 'Process rejection', 850, 900, 100, 80);
n% End events
hiredEndId = 'Endvent_hired';
bpmn.addEvent(hiredEndId, 'Process Ended - Hired', 'end event', '', 1000, 800, 36, 36);
nrejectedEndId = 'Endvent_rejectedend';
bpmn.addEvent(rejectedEndId, 'Process Ended - Rejected', 'end event', '', 1000, 900, 36, 36);
n%% Add data objects and stores
% Application Document
applicationDataId = 'Data_application';
bpmn.addDataObject(applicationDataId, 'Application Document', false, 200, 220, 36, 50);
n% Candidate Database
candidateDbId = 'Dattore_candidatedb';
bpmn.addDataStore(candidateDbId, 'Candidate Database', 1000, 300, 280, 50, 40);
n% Interview Notes
interviewNotesDataId = 'Data_interViewnotes';
bpmn.addDataObject(interviewNotesDataId, 'Interview Notes', true, 450, 280, 36, 50);
n%% Add text annotations
bpmn.addTextAnnotation('Annotation_1', 'Applications Should be Reviewed Within 5 Business Days', 150, 30, 200, 50);
bpmn.addTextAnnotation('Annotation_2', 'Multiple interviews May be Scheduled Based on Position Requirements', 400, 430, 200, 50);
n%% Add Sequence Flows in HR Lane
% Start -> Review Application
bpmn.addSequenceFlow('Flow_1', startEventId, reviewApplicationId, [186, 150; 250, 150]);
n% Review Application -> Check qualifications
bpmn.addSequenceFlow('Flow_2', reviewApplicationId, checkQualificationsId, [350, 150; 400, 150]);
n% Check Qualifications -> Gateway
bpmn.addSequenceFlow('Flow_3', checkQualificationsId, initialReviewGatewayId, [450, 150; 500, 150]);
n% Gateway -> Reject
bpmn.addSequenceFlow('Flow_4', initialReviewGatewayId, rejectApplicationId, [525, 125; 600, 80], '$ {Qualificationsmet == false}');
n% Gateway -> Schedule Interview
bpmn.addSequenceFlow('Flow_5', initialReviewGatewayId, scheduleInterviewId, [525, 175; 600, 200], '$ {Qualificationsmet == True}');
n% Reject -> End
bpmn.addSequenceFlow('Flow_6', rejectApplicationId, rejectionEndId, [700, 80; 750, 80]);
n% Schedule Error -> Reschedule
bpmn.addSequenceFlow('Flow_7', scheduleErrorId, rescheduleId, [618, 258; 680, 280]);
n% Reschedule -> Schedule Interview
bpmn.addSequenceFlow('Flow_8', rescheduleId, scheduleInterviewId, [730, 280; 750, 240; 750, 200; 700, 200]);
n% Schedule Interview -> Interview
bpmn.addSequenceFlow('Flow_9', scheduleInterviewId, interviewId, [650, 200; 650, 270; 200, 270; 200, 350; 250, 350]);
n%% Add Sequence Flows in Manager Lane
% Interview -> Additional interviews
bpmn.addSequenceFlow('Flow_10', interviewId, additionalInterviewId, [350, 350; 400, 350]);
n% Additional interviews -> Decision Gateway
bpmn.addSequenceFlow('Flow_11', additionalInterviewId, hiringDecisionId, [500, 350; 550, 350]);
n% Decision Gateway -> Reject
bpmn.addSequenceFlow('Flow_12', hiringDecisionId, rejectAfterInterviewId, [575, 350; 650, 350], '$ {hire == false}');
n% Decision Gateway -> Approve
bpmn.addSequenceFlow('Flow_13', hiringDecisionId, approveHiringId, [575, 375; 650, 450], '$ {hire == True}');
n% Reject after interview -> End
bpmn.addSequenceFlow('Flow_14', rejectAfterInterviewId, rejectionAfterInterviewEndId, [750, 350; 800, 350]);
n% Approve Hiring -> Prepare Equipment (Cross -Lane)
bpmn.addSequenceFlow('Flow_15', approveHiringId, prepareEquipmentId, [650, 450; 200, 450; 200, 550; 250, 550]);
n%% Add Sequence Flows in IT Lane
% Prepare Equipment -> Setup Accounts
bpmn.addSequenceFlow('Flow_16', prepareEquipmentId, setupAccountsId, [350, 550; 400, 550]);
n% Setup Accounts -> Onboarding subProcess
bpmn.addSequenceFlow('Flow_17', setupAccountsId, onboardingSubprocessId, [500, 550; 550, 550]);
n% Onboarding subProcess -> end
bpmn.addSequenceFlow('Flow_18', onboardingSubprocessId, onboardingCompleteId, [750, 550; 800, 550]);
n%% Add Sequence Flows in Applicant Pool
% Start -> Submit Application
bpmn.addSequenceFlow('Flow_19', applicantStartId, submitApplicationId, [186, 800; 250, 800]);
n% Submit Application -> Wait for Response
bpmn.addSequenceFlow('Flow_20', submitApplicationId, waitForResponseId, [350, 800; 400, 800]);
n% Wait for Response -> Response Gateway
bpmn.addSequenceFlow('Flow_21', waitForResponseId, responseGatewayId, [436, 800; 500, 800]);
n% Response gateway -> rejected
bpmn.addSequenceFlow('Flow_22', responseGatewayId, applicantRejectedId, [525, 775; 600, 750], '$ {Accepted == false}');
n% Response Gateway -> Attend Interview
bpmn.addSequenceFlow('Flow_23', responseGatewayId, attendInterviewId, [525, 825; 600, 850], '$ {Accepted == True}');
n% Rejected -> end
bpmn.addSequenceFlow('Flow_24', applicantRejectedId, applicantRejectionEndId, [700, 750; 750, 750]);
n% Attend Interview -> Final Result
bpmn.addSequenceFlow('Flow_25', attendInterviewId, finalResultGatewayId, [700, 850; 750, 850]);
n% Final Result -> Hired
bpmn.addSequenceFlow('Flow_26', finalResultGatewayId, hiredTaskId, [775, 825; 850, 800], '$ {Hired == True}');
n% Final Result -> Rejected After Interview
bpmn.addSequenceFlow('Flow_27', finalResultGatewayId, rejectedAfterInterviewTaskId, [775, 875; 850, 900], '$ {Hired == false}');
n% Hired -> End
bpmn.addSequenceFlow('Flow_28', hiredTaskId, hiredEndId, [950, 800; 1000, 800]);
n% Rejected after interview -> end
bpmn.addSequenceFlow('Flow_29', rejectedAfterInterviewTaskId, rejectedEndId, [950, 900; 1000, 900]);
n%% Add message flows between pools
% Application submission
bpmn.addMessageFlow('MessageFlow_1', submitApplicationId, startEventId, [300, 780; 300, 700; 168, 700; 168, 168], 'Job application');
n% Interview Invitation
bpmn.addMessageFlow('MessageFlow_2', scheduleInterviewId, waitForResponseId, [650, 240; 650, 500; 418, 500; 418, 782], 'Interview Invitation');
n% Rejection message
bpmn.addMessageFlow('MessageFlow_3', rejectApplicationId, waitForResponseId, [650, 60; 400, 60; 400, 782], 'Rejection notice');
n% Interview coordination
bpmn.addMessageFlow('MessageFlow_4', interviewId, attendInterviewId, [300, 370; 300, 600; 650, 600; 650, 832], 'Interview Communication');
n%% Add Data Associations
% Application Data to Review Task
bpmn.addDataAssociation('DATAASSOC_1', applicationDataId, reviewApplicationId, [218, 245; 275, 190]);
n% Interview Notes
bpmn.addDataAssociation('DATAASSOC_2', interviewId, interviewNotesDataId, [350, 350; 450, 305]);
n% Database Connection
bpmn.addDataAssociation('DATAASSOC_3', hiringDecisionId, candidateDbId, [575, 350; 800, 350; 800, 300; 830, 300]);
n%% Add Association for Annotation
bpmn.addAssociation('Assoc_1', 'Annotation_1', reviewApplicationId, [250, 55; 300, 110], 'None');
bpmn.addAssociation('Assoc_2', 'Annotation_2', additionalInterviewId, [450, 430; 450, 390], 'None');
n%% Save BPMN File
ndisp(['Complex BPMN Diagram saved to:', outputFile]);
n%% Display Successful Completion
disp('Complex BPMN Example Completed SuccessFully!');