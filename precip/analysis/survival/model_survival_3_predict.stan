// Intra-specific competition model for survival: includes intraspecific effects only 
data{
  int<lower=0> N; // observations
  int<lower=0> npreds;
  int<lower=0> Yrs; // years
  int<lower=0> yid[N]; // year id
  
  int<lower=0> nyrs_out; // years out 
  int<lower=0> yid_out[npreds]; //year out id
  
  int<lower=0> G; // groups
  int<lower=0> gid[N]; // group id
  int<lower=0> gid_out[npreds]; // group id holdout
  
  int<lower=0,upper=1> Y[N]; // observation vector
  
  int<lower=0,upper=1> y_holdout[npreds];

  vector[N] X; // size vector
  vector[npreds] Xhold;
  vector[N] W; // intraspecific crowding 
  vector[npreds] Whold; // intraspecific crowding matrix for holdout data 
}
parameters{
  real a_mu;
  vector[Yrs] a;
  real b1_mu;
  vector[Yrs] b1;
  real w;
  real gint[G];
  real<lower=0> sig_a;
  real<lower=0> sig_b1;
  real<lower=0> sig_G;
}
transformed parameters{
  real mu[N];

  vector[N] crowdEff;
  crowdEff <- W*w;
  
  for(n in 1:N){
    mu[n] <- inv_logit(a[yid[n]] + gint[gid[n]] + b1[yid[n]]*X[n] + crowdEff[n]);
  }
  
}
model{
  // Priors
  a_mu ~ normal(0,10);
  w ~ normal(0,10);
  b1_mu ~ normal(0,10);
  sig_a ~ cauchy(0,2);
  sig_b1 ~ cauchy(0,2);
  sig_G ~ cauchy(0,2);
  for(g in 1:G)
    gint[g] ~ normal(0, sig_G);
  for(y in 1:Yrs){
    a[y] ~ normal(a_mu, sig_a);
    b1[y] ~ normal(b1_mu, sig_b1);
  }

  // Likelihood
  Y ~ binomial(1,mu);

}
generated quantities {
  vector[npreds] crowdhat;
  
  vector[nyrs_out] a_out;
  vector[nyrs_out] b1_out;
  
  real muhat[npreds];
  int<lower=0,upper=1> y_hat[npreds]; // pointwise predictions  
  
  vector[npreds] log_lik; // vector for computing log pointwise predictive density  
  
  crowdhat <- Whold*w;
  
  for( i in 1:nyrs_out){
    a_out[i] <- normal_rng(a_mu, sig_a); // draw random year intercept 
    b1_out[i] <- normal_rng(b1_mu, sig_b1); //draw random year x size effect 
  }
  
  
  for(n in 1:npreds){
    muhat[n] <- inv_logit(a_out[yid_out[n]] + gint[gid_out[n]] + b1_out[yid_out[n]]*Xhold[n] + crowdhat[n]);
    
    y_hat[n] <- bernoulli_rng(muhat[n]);
    log_lik[n] <- bernoulli_log(y_holdout[n], muhat[n]);
  }
}

