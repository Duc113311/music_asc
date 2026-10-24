"""Build, version-bump and distribute an APK. Run from the muvik/ folder:

    python build.py                 # menu
    python build.py dev release     # flavor + build type
    python build.py check-strings   # only the translation key check

See tool/build/build_helper.py for what it does and where optional secrets
(Telegram / e-mail / Firebase service account) come from; none is in the repo.
"""
import os
import sys

PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
os.chdir(PROJECT_DIR)
sys.path.insert(0, os.path.join(PROJECT_DIR, "tool", "build"))

from build_helper import main_build  # noqa: E402

if __name__ == "__main__":
    main_build(
        argv=sys.argv,
        package_name="com.asctechsoft.muvik",
        # Same recipients as smart_drink. Override with ASC_TESTER_EMAILS,
        # ASC_EMAIL_TO, ASC_EMAIL_FROM. The e-mail password is NOT here: set
        # ASC_EMAIL_PASSWORD or tool/build/build_secrets.json.
        tester_emails="asctechsoft888@gmail.com",
        email_to="dsp.entertainment.99@gmail.com",
        email_from="dsp.entertainment.99@gmail.com",
    )
