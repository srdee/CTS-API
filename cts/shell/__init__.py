#!/usr/bin/python
# -*- coding: utf-8 -*-


def documentTestResults(results):
    """ Print test results

    :param results: A list of tests results associated in a tuple with a Text.id
    :type results: list(tuple(str, tuple(list(boolean), list(ConsoleObject))))
    :returns: List of ConsoleObject
    :rtype: list(ConsoleObject)
    """
    ret = []
    for result in results:
        textName, raw_results = result
        status, messages = raw_results
        i = 0
        for b in status:
            if b is True:
                ret.append(Success("Level {0} Citation Mapping for document {1} is working".format(i + 1, textName)))
            else:
                ret.append(Error("Level {0} Citation Mapping for document {1} is failing".format(i + 1, textName)))
            i += 1

        ret = ret + messages

    return ret


class color:
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


class ConsoleObject(object):
    def __init__(self, string):
        """ Defines the string to print

        :param string: A terminal related object
        :type string: unicode or str

        """
        self.string = string

    def __str__(self):
        """ Return a str representation of the object """
        return self.string

    def to_string(self):
        return self.string


class Command(ConsoleObject):
    """ An object representing a command to run """
    def __init__(self, string):
        super(Command, self).__init__(string=string)


class Request(ConsoleObject):
    """ An object representing details about a command to run """
    def __init__(self, string):
        """ Defines the string to print

        :param string: A command to be run a copy/past way into a shell
        :type string: unicode or str

        """
        super(Request, self).__init__(string=string)

    def __str__(self):
        """ Return a str representation of the object """
        return "{0}Program Request{3} : {2}{1}{3}".format(color.UNDERLINE, self.string, color.BLUE, color.END)


class Helper(ConsoleObject):
    """ An object representing details about a command to run """
    def __init__(self, string):
        """ Defines the string to print

        :param string: A command to be run a copy/past way into a shell
        :type string: unicode or str

        """
        super(Helper, self).__init__(string=string)

    def __str__(self):
        """ Return a str representation of the object """
        return "{0}Command to run on another console{3} : {2}{1}{3}".format(color.BOLD, self.string, color.DARKCYAN, color.END)


class Parameter(ConsoleObject):
    """ An object representing informations the user should input in a setup process for example """
    def __init__(self, string):
        """ Defines the string to print

        :param string: An answer to a prompted question
        :type string: unicode or str

        """
        super(Parameter, self).__init__(string=string)

    def __str__(self):
        return "{0}Proposed Input{3} : {2}{1}{3}".format(color.UNDERLINE, self.string, color.DARKCYAN, color.END)


class Separator(ConsoleObject):
    """ A decoration object """
    def __init__(self):
        super(Separator, self).__init__(string="#############")


class Success(ConsoleObject):
    """ A Warning String """
    def __init__(self, string):
        super(Success, self).__init__(string=string)

    def __str__(self):
        return "{0}{1}{2}".format(color.GREEN, self.string, color.END)


class Warning(ConsoleObject):
    """ A Warning String """
    def __init__(self, string):
        super(Warning, self).__init__(string=string)

    def __str__(self):
        return "{0}{1}{2}".format(color.ORANGE, self.string, color.END)


class Error(ConsoleObject):
    """ An Error String """
    def __init__(self, string):
        super(Error, self).__init__(string=string)

    def __str__(self):
        return "{3}{0}{1}{2}".format(color.RED, self.string, color.END, color.BOLD)


def is_msg(cmd):
    return isinstance(cmd, (Parameter, Helper, Request, Separator, Warning, Success, Error))


def run(cmds, host_fn):
    """ Given a variable cmds, decides whether to prompt user with a command to run or run it using given host_fn function

    :param cmds: The command to print. If a list, we run the command using host_fn()
    :type cmds: unicode or str or list
    :param host_fn: Function to use to run cmds (Default : local)
    :type host_fn: function

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

        if is_msg(last_cmd):
            raw_input("Press enter to continue")
