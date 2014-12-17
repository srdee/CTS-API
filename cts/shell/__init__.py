#!/usr/bin/python
# -*- coding: utf-8 -*-


def documentTestResults(results, no_color=False):
    """ Print test results

    :param results: A list of tests results associated in a tuple with a Text.id
    :type results: list(tuple(str, tuple(list(boolean), list(ConsoleObject))))
    :param no_color: Indicates if we should have non-styled string messages
    :type no_color: boolean
    :returns: List of ConsoleObject
    :rtype: list(ConsoleObject)
    """
    ret = []

    successes = 0
    failures = 0

    for result in results:
        textName, raw_results = result
        status, messages = raw_results
        textName = textName

        if len(messages) == 0 and len([m for m in status if m is False]) == 0:
            messages.append(Success("Document {0} has passed all the tests".format(textName)))
            successes += 1
        else:
            failures += 1
            i = 0
            for b in status:
                if b is True:
                    messages.append(Success("Level {0} Citation Mapping for document {1} is working".format(i + 1, textName)))
                else:
                    messages.append(Error("Level {0} Citation Mapping for document {1} is failing".format(i + 1, textName)))
                i += 1

            not_errors = [msg for msg in messages if not isinstance(msg, (Warning, Error))]

            errors = [NumberedError(messages.index(error) + 1, error.string) for error in messages if isinstance(error, (Error, Warning))]
            messages = not_errors
            if len(errors) > 0:
                messages = [Warning("Document {0} encountered following errors".format(textName))] + not_errors + errors

        ret = ret + messages

    if failures == 0:
        ret.append(Success("All {0} files have passed tests successfuly").format(successes))
    else:
        ret.append(Error("{0}/{1} files have passed tests successfuly".format(successes, successes + failures)))

    if no_color is True:
        ret2 = []
        for r in ret:
            r.color = NOCOLOR
            ret2.append(r)
        ret = ret2
    return ret


class COLOR:
    """ A class with styles bytes for print() function """
    PURPLE = '\033[95m'
    CYAN = '\033[96m'
    ORANGE = '\33[43m'
    DARKCYAN = '\033[36m'
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'


class NOCOLOR:
    """ A class with normal styles bytes for print() function """
    PURPLE = ''
    CYAN = ''
    ORANGE = ''
    DARKCYAN = ''
    BLUE = ''
    GREEN = ''
    YELLOW = ''
    RED = ''
    BOLD = ''
    UNDERLINE = ''
    END = ''


class ConsoleObject(object):
    def __init__(self, string, color=None):
        """ Defines the string to print

        :param string: A terminal related object
        :type string: unicode or str

        """
        self.string = string
        self.color = color
        if self.color is None:
            self.color = COLOR

    def __str__(self):
        """ Return a str representation of the object """
        return self.string

    def to_string(self):
        return self.string


class Command(ConsoleObject):
    """ An object representing a command to run """
    def __init__(self, string, color=None):
        super(Command, self).__init__(string=string, color=color)


class Request(ConsoleObject):
    """ An object representing details about a command to run """
    def __init__(self, string, color=None):
        """ Defines the string to print

        :param string: A command to be run a copy/past way into a shell
        :type string: unicode or str

        """
        super(Request, self).__init__(string=string, color=color)

    def __str__(self):
        """ Return a str representation of the object """
        return "{0}Program Request{3} : {2}{1}{3}".format(self.color.UNDERLINE, self.string, self.color.BLUE, self.color.END)


class Helper(ConsoleObject):
    """ An object representing details about a command to run """
    def __init__(self, string, color=None):
        """ Defines the string to print

        :param string: A command to be run a copy/past way into a shell
        :type string: unicode or str

        """
        super(Helper, self).__init__(string=string, color=color)

    def __str__(self):
        """ Return a str representation of the object """
        return "{0}Command to run on another console{3} : {2}{1}{3}".format(self.color.BOLD, self.string, self.color.DARKCYAN, self.color.END)


class Parameter(ConsoleObject):
    """ An object representing informations the user should input in a setup process for example """
    def __init__(self, string, color=None):
        """ Defines the string to print

        :param string: An answer to a prompted question
        :type string: unicode or str

        """
        super(Parameter, self).__init__(string=string, color=color)

    def __str__(self):
        return "{0}Proposed Input{3} : {2}{1}{3}".format(self.color.UNDERLINE, self.string, self.color.DARKCYAN, self.color.END)


class Separator(ConsoleObject):
    """ A decoration object """
    def __init__(self):
        super(Separator, self).__init__(string="#############")


class Success(ConsoleObject):
    """ A Warning String """
    def __init__(self, string, color=None):
        super(Success, self).__init__(string=string, color=color)

    def __str__(self):
        return "{0}{1}{2}".format(self.color.GREEN, self.string, self.color.END)


class Warning(ConsoleObject):
    """ A Warning String """
    def __init__(self, string, color=None):
        super(Warning, self).__init__(string=string, color=color)

    def __str__(self):
        return "{0}{1}{2}".format(self.color.ORANGE, self.string, self.color.END)


class Error(ConsoleObject):
    """ An Error String """
    def __init__(self, string, color=None):
        super(Error, self).__init__(string=string, color=color)

    def __str__(self):
        return "{3}{0}{1}{2}".format(self.color.RED, self.string, self.color.END, self.color.BOLD)


class NumberedError(ConsoleObject):
    """ An NumberedError String """
    def __init__(self, number, string, color=None):
        super(NumberedError, self).__init__(string=string, color=color)
        self.number = number

    def __str__(self):
        return "{3}{0}Error number {4}{2}: {1}".format(self.color.RED, self.string, self.color.END, self.color.BOLD, self.number)


def is_msg(cmd):
    return isinstance(cmd, (Parameter, Helper, Request, Separator, Warning, Success, Error, NumberedError))


def run(cmds, host_fn, input_required=True):
    """ Given a variable cmds, decides whether to prompt user with a command to run or run it using given host_fn function

    :param cmds: The command to print. If a list, we run the command using host_fn()
    :type cmds: unicode or str or list
    :param host_fn: Function to use to run cmds (Default : local)
    :type host_fn: function
    :param input_required: Indicates if we should ask user to confirm he has read everything
    :type input_required: boolean

    """
    if is_msg(cmds):
        print(cmds)

    elif isinstance(cmds, Command):
        host_fn(cmds.to_string())

    elif isinstance(cmds, list):
        last_cmd = None

        for cmd in cmds:
            if last_cmd != type(cmd):
                if last_cmd and is_msg(cmd) is True and isinstance(cmd, (Command)) is True:  # If our last ConsoleObject was a string to print and the next one is a Command to run, we need to ask if user is ok with it
                        raw_input("Press enter when you have done previous steps")
                last_cmd = cmd
            run(cmd, host_fn)

        if is_msg(last_cmd) and input_required is True:
            raw_input("Press enter to continue")
