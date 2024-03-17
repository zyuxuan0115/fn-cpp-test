use curl::easy::{Easy};
use std::io::{self, stdin, Read, stdout, Write};

fn make_rpc(func_name: &str, mut input: &[u8]) -> String {
  let mut easy = Easy::new();
  let mut url = String::from("http://gateway.openfaas.svc.cluster.local.:8080/function/");
  url.push_str(func_name);
  easy.url(&url).unwrap();
  easy.post(true).unwrap();
  easy.post_field_size(input.len() as u64).unwrap();

  let mut html_data = String::new();
  {
    let mut transfer = easy.transfer();
    transfer.read_function(|buf| {
      Ok(input.read(buf).unwrap_or(0))
    }).unwrap();

    transfer.write_function(|data| {
      html_data = String::from_utf8(Vec::from(data)).unwrap();
      Ok(data.len())
    }).unwrap();

    transfer.perform().unwrap();
  }
  html_data
}

fn main() {

  let mut buffer = String::new();
  io::stdin().read_line(&mut buffer);
  let mut prefix: String = "From Rust Caller: ".to_owned();
  prefix.push_str(&buffer);
  let mut data = (&prefix).as_bytes();
  let result = make_rpc("callee-rust", data);

  println!("{}", result);
}
