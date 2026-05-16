public class UTI_GrantValidator {

    public static List<String> validate(GrantApplicationWrapper request) {

        List<String> errors = new List<String>();

        // First Name
        if (String.isBlank(request.firstName)) {
            errors.add('First Name is required.');
        }

        // Last Name
        if (String.isBlank(request.lastName)) {
            errors.add('Last Name is required.');
        }

        // Phone Validation
        if (String.isBlank(request.phone)) {

            errors.add('Phone is required.');

        } else {
            if (!Pattern.matches('^65\\d{8}$', request.phone)) {
                errors.add(
                    'Phone must be exactly 10 digits starting with 65.'
                );
            }
        }

        // Postal Code
        if (String.isBlank(request.postalCode)) {

            errors.add('Postal Code is required.');

        } else {

            if (!Pattern.matches('^\\d{6}$', request.postalCode)) {
                errors.add(
                    'Postal Code must be exactly 6 numeric digits.'
                );
            }
        }

        // Monthly Income
        if (request.monthlyIncome == null ||
            request.monthlyIncome <= 0) {

            errors.add(
                'Monthly Income must be greater than zero.'
            );
        }

        // Support Option
        if (String.isBlank(request.supportOption)) {
            errors.add('Support Option is required.');
        }

        return errors;
    }
}