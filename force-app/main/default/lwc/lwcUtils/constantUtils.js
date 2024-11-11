class ConstantUtils {
    SUCCESS_LABEL = 'Success';
    ERROR_LABEL = 'Error';

    CASE_CONVERSION_MESSAGES = {
        SUCCESS_MESSAGE : 'Case converted to lead successfully!',
        SUCCESS_MESSAGE_OPP : 'Case converted to opportunity successfully!',
        WEB_FIELDS_ERROR_MESSAGE : 'Case could not be converted to lead. Missed fields on Case: {0}!',
        WEB_FIELDS_ERROR_MESSAGE_OPP : 'Case could not be converted to opportunity. Missed fields on Case: {0}!',
        PROJECT_DATA_MISSED_ERROR_MESSAGE : '"Project Name" or "Project Address" should be populate!',
        FATAL_ERROR_MESSAGE : 'Fatal Error! Please contact the administrator'
    };
}

const constantUtils = new ConstantUtils();

export default constantUtils;