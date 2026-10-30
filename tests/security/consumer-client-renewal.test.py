import importlib.util
import io
import json
import unittest
import urllib.error
from pathlib import Path

spec=importlib.util.spec_from_file_location('consumer_client',Path(__file__).resolve().parents[2]/'examples/consumer_client_credentials.py')
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)

class RenewalTests(unittest.TestCase):
    def setUp(self):
        self.now=0;self.issued=0;self.queried=0;self.status=200
        def opener(request,timeout):
            if request.full_url==module.TOKEN_URL:
                self.issued+=1
                return io.BytesIO(json.dumps({'access_token':str(self.issued)*64,'expires_in':900,'token_type':'Bearer'}).encode())
            self.queried+=1
            if self.status!=200:raise urllib.error.HTTPError(request.full_url,self.status,'denied',{},None)
            return io.BytesIO(b'{"success":true}')
        self.client=module.ConsumerClient('test','not-a-real-secret',opener=opener,clock=lambda:self.now)
    def test_cache_and_renew_before_expiry(self):
        self.client.query('q',{});self.now=869;self.client.query('q',{})
        self.assertEqual(self.issued,1)
        self.now=870;self.client.query('q',{})
        self.assertEqual(self.issued,2)
    def test_only_one_retry_for_401(self):
        self.status=401
        with self.assertRaises(urllib.error.HTTPError):self.client.query('q',{})
        self.assertEqual((self.issued,self.queried),(2,2))
    def test_forbidden_does_not_renew(self):
        self.status=403
        with self.assertRaises(urllib.error.HTTPError):self.client.query('q',{})
        self.assertEqual((self.issued,self.queried),(1,1))

if __name__=='__main__':unittest.main()
