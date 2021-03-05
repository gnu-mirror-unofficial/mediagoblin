import functools
import warnings

from email.mime.text import MIMEText


def encode_to_utf8(method):
    def wrapper(self):
        return method(self)
    functools.update_wrapper(wrapper, method, ['__name__', '__doc__'])
    return wrapper


# based on django.utils.encoding.python_2_unicode_compatible
def py2_unicode(klass):
    return klass
